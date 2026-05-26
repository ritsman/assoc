import { Router } from "express";
import prismaPkg from "@prisma/client";
import { z } from "zod";
import { buildDefaultMemberPasswordHash } from "../lib/auth.js";
import { prisma } from "../lib/prisma.js";
import {
  requireAdminUser,
  requireAuthenticatedSession,
} from "../lib/session-auth.js";

const router = Router();
const { ApprovalStatus, MemberStatus } = prismaPkg;

const accessStatusSchema = z.object({
  accessStatus: z.enum(["PENDING", "APPROVED", "SUSPENDED", "CANCELLED"]),
});
const adminRoleSchema = z.object({
  isAdmin: z.boolean(),
});

function serializeUser(user) {
  const { passwordHash, ...safeUser } = user;
  return safeUser;
}

function buildAccessUpdate(accessStatus) {
  switch (accessStatus) {
    case "APPROVED":
      return {
        user: {
          approvalStatus: ApprovalStatus.APPROVED,
          isActive: true,
          approvedAt: new Date(),
          rejectedAt: null,
        },
        memberStatus: MemberStatus.ACTIVE,
      };
    case "SUSPENDED":
      return {
        user: {
          approvalStatus: ApprovalStatus.APPROVED,
          isActive: false,
        },
        memberStatus: MemberStatus.INACTIVE,
      };
    case "CANCELLED":
      return {
        user: {
          approvalStatus: ApprovalStatus.REJECTED,
          isActive: false,
          approvedAt: null,
          rejectedAt: new Date(),
        },
        memberStatus: MemberStatus.INACTIVE,
      };
    case "PENDING":
    default:
      return {
        user: {
          approvalStatus: ApprovalStatus.PENDING,
          isActive: true,
          approvedAt: null,
          rejectedAt: null,
        },
        memberStatus: MemberStatus.PENDING,
      };
  }
}

function resolveViewerRole(user) {
  if (user.isAdmin) {
    return "admin";
  }

  if (user.isMember) {
    return "member";
  }

  if (user.isVendor) {
    return "vendor";
  }

  return "viewOnly";
}

router.get(
  "/",
  requireAuthenticatedSession,
  requireAdminUser,
  async (req, res) => {
    const { associationId, role } = req.query;

    const users = await prisma.user.findMany({
      where: {
        ...(associationId ? { associationId: String(associationId) } : {}),
        ...(role === "member" ? { isMember: true } : {}),
        ...(role === "vendor" ? { isVendor: true } : {}),
      },
      include: {
        member: true,
        vendor: true,
      },
      orderBy: { createdAt: "desc" },
    });

    res.json({ users: users.map(serializeUser) });
  },
);

router.get(
  "/session-report",
  requireAuthenticatedSession,
  requireAdminUser,
  async (req, res) => {
    const activeWindowMinutes = Math.max(
      1,
      Math.min(120, Number(req.query.activeWindowMinutes || 5)),
    );
    const now = new Date();
    const activeSince = new Date(
      now.getTime() - activeWindowMinutes * 60 * 1000,
    );
    const associationId = req.auth.user.associationId || undefined;

    const sessions = await prisma.userSession.findMany({
      where: {
        revokedAt: null,
        refreshExpiresAt: {
          gt: now,
        },
        user: {
          ...(associationId ? { associationId } : {}),
        },
      },
      include: {
        user: true,
      },
      orderBy: {
        lastSeenAt: "desc",
      },
    });

    const loggedInUserIds = new Set(sessions.map((session) => session.userId));
    const activeSessions = sessions.filter(
      (session) => session.lastSeenAt >= activeSince,
    );
    const activeUserIds = new Set(
      activeSessions.map((session) => session.userId),
    );
    const todayStart = new Date(
      Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()),
    );

    res.json({
      summary: {
        activeWindowMinutes,
        loggedInUsers: loggedInUserIds.size,
        activeUsers: activeUserIds.size,
        totalSessions: sessions.length,
        activeSessions: activeSessions.length,
        sessionsToday: sessions.filter(
          (session) => session.createdAt >= todayStart,
        ).length,
      },
      sessions: sessions.map((session) => ({
        sessionId: session.id,
        userId: session.userId,
        displayName: [session.user.firstName, session.user.lastName]
          .filter(Boolean)
          .join(" ")
          .trim(),
        email: session.user.email,
        viewerRole: resolveViewerRole(session.user),
        isActiveNow: session.lastSeenAt >= activeSince,
        createdAt: session.createdAt,
        lastSeenAt: session.lastSeenAt,
        expiresAt: session.expiresAt,
        refreshExpiresAt: session.refreshExpiresAt,
        deviceInfo: session.deviceInfo,
        userAgent: session.userAgent,
        ipAddress: session.ipAddress,
      })),
    });
  },
);

router.patch(
  "/:id/access",
  requireAuthenticatedSession,
  requireAdminUser,
  async (req, res) => {
    const parsed = accessStatusSchema.safeParse(req.body);

    if (!parsed.success) {
      return res.status(400).json({
        error: "Invalid user access payload",
        details: parsed.error.flatten(),
      });
    }

    const user = await prisma.user.findUnique({
      where: { id: req.params.id },
    });

    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    const { user: userData, memberStatus } = buildAccessUpdate(
      parsed.data.accessStatus,
    );

    const updatedUser = await prisma.$transaction(async (tx) => {
      const nextUser = await tx.user.update({
        where: { id: req.params.id },
        data: {
          ...userData,
          ...(parsed.data.accessStatus === "APPROVED" && user.isMember
            ? { passwordHash: await buildDefaultMemberPasswordHash() }
            : {}),
        },
        include: {
          member: true,
        },
      });

      if (nextUser.memberId) {
        await tx.member.update({
          where: { id: nextUser.memberId },
          data: {
            membershipStatus: memberStatus,
          },
        });
      }

      return nextUser;
    });

    return res.json({ user: serializeUser(updatedUser) });
  },
);

router.patch(
  "/:id/admin-role",
  requireAuthenticatedSession,
  requireAdminUser,
  async (req, res) => {
    const parsed = adminRoleSchema.safeParse(req.body);

    if (!parsed.success) {
      return res.status(400).json({
        error: "Invalid admin role payload",
        details: parsed.error.flatten(),
      });
    }

    const targetUser = await prisma.user.findUnique({
      where: { id: req.params.id },
      include: {
        member: true,
      },
    });

    if (!targetUser) {
      return res.status(404).json({ error: "User not found" });
    }

    if (!targetUser.isMember) {
      return res.status(400).json({
        error: "Only member accounts can be promoted to admin right now.",
      });
    }

    if (
      parsed.data.isAdmin &&
      (targetUser.approvalStatus !== ApprovalStatus.APPROVED ||
        !targetUser.isActive)
    ) {
      return res.status(400).json({
        error: "Only approved active members can be promoted to admin.",
      });
    }

    const updatedUser = await prisma.user.update({
      where: { id: req.params.id },
      data: {
        isAdmin: parsed.data.isAdmin,
        isActive: true,
        ...(parsed.data.isAdmin
          ? {
              approvalStatus: ApprovalStatus.APPROVED,
              approvedAt: targetUser.approvedAt ?? new Date(),
              rejectedAt: null,
            }
          : {}),
      },
      include: {
        member: true,
        vendor: true,
      },
    });

    return res.json({ user: serializeUser(updatedUser) });
  },
);

export default router;
