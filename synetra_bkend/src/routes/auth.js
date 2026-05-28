import { Router } from "express";
import { z } from "zod";
import { prisma } from "../lib/prisma.js";
import {
  hashPassword,
  isManagedDefaultPasswordHash,
  verifyPassword,
} from "../lib/auth.js";
import {
  createUserSession,
  refreshUserSession,
  requireAuthenticatedSession,
  revokeSessionById,
} from "../lib/session-auth.js";

const router = Router();

const loginSchema = z.object({
  username: z.string().min(1),
  password: z.string().min(1),
});

const changePasswordSchema = z.object({
  username: z.string().min(1),
  currentPassword: z.string().min(1),
  newPassword: z.string().min(8),
});

const refreshSchema = z.object({
  refreshToken: z.string().min(1),
});

function resolveViewerRole(user) {
  if (user.isAdmin) {
    return "admin";
  }

  if (user.isVendor) {
    return "vendor";
  }

  if (user.isMember) {
    return "member";
  }

  return "viewOnly";
}

function serializeSession(user, session = null) {
  return {
    ...(session
      ? {
          auth: {
            ...(session.token ? { token: session.token } : {}),
            ...(session.refreshToken
              ? { refreshToken: session.refreshToken }
              : {}),
            sessionId: session.session.id,
            expiresAt: session.session.expiresAt,
            refreshExpiresAt: session.session.refreshExpiresAt,
            lastSeenAt: session.session.lastSeenAt,
          },
        }
      : {}),
    user: {
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      displayName: [user.firstName, user.lastName]
        .filter(Boolean)
        .join(" ")
        .trim(),
      associationId: user.associationId,
      memberId: user.memberId,
      viewerRole: resolveViewerRole(user),
      mustChangePassword: isManagedDefaultPasswordHash(user.passwordHash),
      approvalStatus: user.approvalStatus,
      isActive: user.isActive,
    },
  };
}

router.post("/login", async (req, res) => {
  const parsed = loginSchema.safeParse(req.body);

  if (!parsed.success) {
    return res.status(400).json({
      error: "Invalid login payload",
      details: parsed.error.flatten(),
    });
  }

  const username = parsed.data.username.trim().toLowerCase();
  const user = await prisma.user.findFirst({
    where: {
      email: {
        equals: username,
        mode: "insensitive",
      },
    },
  });

  if (
    !user ||
    !(await verifyPassword(parsed.data.password, user.passwordHash))
  ) {
    return res.status(401).json({ error: "Invalid username or password" });
  }

  if (!user.isActive) {
    return res.status(403).json({ error: "This account is inactive" });
  }

  if (user.isMember && user.approvalStatus !== "APPROVED") {
    return res.status(403).json({
      error: "Your member profile is not approved yet",
    });
  }

  if (user.isVendor && user.approvalStatus !== "APPROVED") {
    return res.status(403).json({
      error: "Your vendor profile is not approved yet",
    });
  }

  const session = await createUserSession({ userId: user.id, req });

  return res.json(serializeSession(user, session));
});

router.get("/me", requireAuthenticatedSession, async (req, res) => {
  return res.json(
    serializeSession(req.auth.user, {
      token: req.auth.token,
      session: req.auth.session,
    }),
  );
});

router.post("/logout", requireAuthenticatedSession, async (req, res) => {
  await revokeSessionById(req.auth.session.id);
  return res.json({ ok: true });
});

router.post("/refresh", async (req, res) => {
  const parsed = refreshSchema.safeParse(req.body);

  if (!parsed.success) {
    return res.status(400).json({
      error: "Invalid refresh payload",
      details: parsed.error.flatten(),
    });
  }

  const refreshedSession = await refreshUserSession({
    refreshToken: parsed.data.refreshToken,
    req,
  });

  if (!refreshedSession) {
    return res.status(401).json({
      error: "Refresh token expired or invalid. Please sign in again.",
    });
  }

  return res.json(serializeSession(refreshedSession.user, refreshedSession));
});

router.post("/change-password", async (req, res) => {
  const parsed = changePasswordSchema.safeParse(req.body);

  if (!parsed.success) {
    return res.status(400).json({
      error: "Invalid change password payload",
      details: parsed.error.flatten(),
    });
  }

  const username = parsed.data.username.trim().toLowerCase();
  const user = await prisma.user.findFirst({
    where: {
      email: {
        equals: username,
        mode: "insensitive",
      },
    },
  });

  if (
    !user ||
    !(await verifyPassword(parsed.data.currentPassword, user.passwordHash))
  ) {
    return res.status(401).json({ error: "Current password is incorrect" });
  }

  await prisma.user.update({
    where: { id: user.id },
    data: {
      passwordHash: await hashPassword(parsed.data.newPassword),
    },
  });

  return res.json({ ok: true });
});

export default router;
