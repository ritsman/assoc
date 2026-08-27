import { Router } from "express";
import prismaPkg from "@prisma/client";
import { z } from "zod";
import { buildDefaultMemberPasswordHash, hashPassword } from "../lib/auth.js";
import { prisma } from "../lib/prisma.js";
import {
  requireAdminUser,
  requireAuthenticatedSession,
} from "../lib/session-auth.js";

const router = Router();
const { ApprovalStatus, MemberStatus } = prismaPkg;
const DEFAULT_SUPER_ADMIN_PASSWORD =
  process.env.DEFAULT_SUPER_ADMIN_PASSWORD || "Admin@123";

const accessStatusSchema = z.object({
  accessStatus: z.enum(["PENDING", "APPROVED", "SUSPENDED", "CANCELLED"]),
});
const adminRoleSchema = z
  .object({
    role: z.enum(["member", "admin", "superAdmin"]).optional(),
    isAdmin: z.boolean().optional(),
  })
  .refine((value) => value.role || typeof value.isAdmin === "boolean", {
    message: "Either role or isAdmin must be provided",
  });
const createSuperAdminSchema = z.object({
  email: z.string().email(),
  firstName: z.string().trim().optional(),
  lastName: z.string().trim().optional(),
});

const createBackendAdminSchema = z.object({
  email: z.string().email(),
  firstName: z.string().trim().optional(),
  lastName: z.string().trim().optional(),
});
const updateCurrentUserSchema = z.object({
  email: z.string().email(),
  firstName: z.string().trim().min(1),
  lastName: z.string().trim().optional(),
  phone: z.string().trim().optional(),
});

function buildNamesFromEmail(email) {
  const localPart = String(email || "")
    .split("@")[0]
    .replace(/[._-]+/g, " ")
    .trim();

  if (!localPart) {
    return {
      firstName: "Super",
      lastName: "Admin",
    };
  }

  const segments = localPart
    .split(" ")
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1));

  return {
    firstName: segments[0] || "Super",
    lastName: segments.slice(1).join(" ") || "Admin",
  };
}

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
  if (user.isSuperAdmin) {
    return "superAdmin";
  }

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
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const sixMonthsAgo = new Date(
      now.getFullYear(),
      now.getMonth() - 5,
      1,
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
    const recentSessions = await prisma.userSession.findMany({
      where: {
        lastSeenAt: {
          gte: sixMonthsAgo,
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
    const monthActiveUserIds = new Set(
      recentSessions
        .filter((session) => session.lastSeenAt >= monthStart)
        .map((session) => session.userId),
    );
    const sixMonthActiveUserIds = new Set(
      recentSessions.map((session) => session.userId),
    );
    const todayStart = new Date(
      Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()),
    );

    res.json({
      summary: {
        activeWindowMinutes,
        loggedInUsers: loggedInUserIds.size,
        activeUsers: activeUserIds.size,
        activeUsersThisMonth: monthActiveUserIds.size,
        activeUsersLastSixMonths: sixMonthActiveUserIds.size,
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

router.get("/me", requireAuthenticatedSession, async (req, res) => {
  const user = await prisma.user.findUnique({
    where: { id: req.auth.user.id },
  });

  if (!user) {
    return res.status(404).json({ error: "User not found" });
  }

  return res.json({ user: serializeUser(user) });
});

router.patch("/me", requireAuthenticatedSession, async (req, res) => {
  const parsed = updateCurrentUserSchema.safeParse(req.body);

  if (!parsed.success) {
    return res.status(400).json({
      error: "Invalid profile payload",
      details: parsed.error.flatten(),
    });
  }

  const email = parsed.data.email.trim().toLowerCase();
  const firstName = parsed.data.firstName.trim();
  const lastName = parsed.data.lastName?.trim() || "";
  const phone = parsed.data.phone?.trim() || null;

  const existingUser = await prisma.user.findUnique({
    where: { email },
  });

  if (existingUser && existingUser.id !== req.auth.user.id) {
    return res.status(409).json({
      error: "Another user already uses this email address.",
    });
  }

  const user = await prisma.user.update({
    where: { id: req.auth.user.id },
    data: {
      email,
      firstName,
      lastName,
      phone,
    },
  });

  return res.json({ user: serializeUser(user) });
});

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

    const requestedRole =
      parsed.data.role ??
      (parsed.data.isAdmin === true ? "admin" : "member");

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
      requestedRole !== "member" &&
      (targetUser.approvalStatus !== ApprovalStatus.APPROVED ||
        !targetUser.isActive)
    ) {
      return res.status(400).json({
        error: "Only approved active members can be promoted to admin.",
      });
    }

    if (requestedRole === "superAdmin" && !req.auth.user.isSuperAdmin) {
      return res.status(403).json({
        error: "Only a super admin can create another super admin.",
      });
    }

    if (
      requestedRole !== "superAdmin" &&
      targetUser.isSuperAdmin
    ) {
      if (!req.auth.user.isSuperAdmin) {
        return res.status(403).json({
          error: "Only a super admin can remove super admin access.",
        });
      }

      const superAdminCount = await prisma.user.count({
        where: {
          isSuperAdmin: true,
          isActive: true,
        },
      });

      if (superAdminCount <= 1) {
        return res.status(400).json({
          error: "At least one super admin must remain active.",
        });
      }
    }

    const updatedUser = await prisma.user.update({
      where: { id: req.params.id },
      data: {
        isAdmin: requestedRole !== "member",
        isSuperAdmin: requestedRole === "superAdmin",
        isActive: true,
        ...(requestedRole !== "member"
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

router.post(
  "/super-admins",
  requireAuthenticatedSession,
  requireAdminUser,
  async (req, res) => {
    if (!req.auth.user.isSuperAdmin) {
      return res.status(403).json({
        error: "Only a super admin can create another super admin.",
      });
    }

    const parsed = createSuperAdminSchema.safeParse(req.body);

    if (!parsed.success) {
      return res.status(400).json({
        error: "Invalid super admin payload",
        details: parsed.error.flatten(),
      });
    }

    const email = parsed.data.email.trim().toLowerCase();
    const derivedNames = buildNamesFromEmail(email);
    const firstName =
      parsed.data.firstName?.trim() || derivedNames.firstName;
    const lastName = parsed.data.lastName?.trim() || derivedNames.lastName;
    const passwordHash = await hashPassword(DEFAULT_SUPER_ADMIN_PASSWORD);

    const existingUser = await prisma.user.findUnique({
      where: { email },
      include: {
        member: true,
        vendor: true,
      },
    });

    const user = existingUser
      ? await prisma.user.update({
          where: { id: existingUser.id },
          data: {
            associationId:
              req.auth.user.associationId || existingUser.associationId,
            firstName: existingUser.firstName || firstName,
            lastName: existingUser.lastName || lastName,
            passwordHash,
            isAdmin: true,
            isSuperAdmin: true,
            isActive: true,
            approvalStatus: ApprovalStatus.APPROVED,
            approvedAt: existingUser.approvedAt ?? new Date(),
            rejectedAt: null,
          },
          include: {
            member: true,
            vendor: true,
          },
        })
      : await prisma.user.create({
          data: {
            associationId: req.auth.user.associationId || null,
            firstName,
            lastName,
            email,
            passwordHash,
            isAdmin: true,
            isSuperAdmin: true,
            isActive: true,
            approvalStatus: ApprovalStatus.APPROVED,
            approvedAt: new Date(),
          },
          include: {
            member: true,
            vendor: true,
          },
        });

    return res.status(existingUser ? 200 : 201).json({
      user: serializeUser(user),
      defaultPassword: DEFAULT_SUPER_ADMIN_PASSWORD,
    });
  },
);

router.post(
  "/backend-admins",
  requireAuthenticatedSession,
  requireAdminUser,
  async (req, res) => {
    if (!req.auth.user.isSuperAdmin) {
      return res.status(403).json({
        error: "Only a super admin can create a backend admin.",
      });
    }

    const parsed = createBackendAdminSchema.safeParse(req.body);

    if (!parsed.success) {
      return res.status(400).json({
        error: "Invalid backend admin payload",
        details: parsed.error.flatten(),
      });
    }

    const email = parsed.data.email.trim().toLowerCase();
    const derivedNames = buildNamesFromEmail(email);
    const firstName =
      parsed.data.firstName?.trim() || derivedNames.firstName;
    const lastName = parsed.data.lastName?.trim() || derivedNames.lastName;
    const passwordHash = await hashPassword(DEFAULT_SUPER_ADMIN_PASSWORD);

    const existingUser = await prisma.user.findUnique({
      where: { email },
      include: {
        member: true,
        vendor: true,
      },
    });

    const user = existingUser
      ? await prisma.user.update({
          where: { id: existingUser.id },
          data: {
            associationId:
              req.auth.user.associationId || existingUser.associationId,
            firstName: existingUser.firstName || firstName,
            lastName: existingUser.lastName || lastName,
            passwordHash,
            isAdmin: true,
            isSuperAdmin: false,
            isActive: true,
            approvalStatus: ApprovalStatus.APPROVED,
            approvedAt: existingUser.approvedAt ?? new Date(),
            rejectedAt: null,
          },
          include: {
            member: true,
            vendor: true,
          },
        })
      : await prisma.user.create({
          data: {
            associationId: req.auth.user.associationId || null,
            firstName,
            lastName,
            email,
            passwordHash,
            isAdmin: true,
            isSuperAdmin: false,
            isActive: true,
            approvalStatus: ApprovalStatus.APPROVED,
            approvedAt: new Date(),
          },
          include: {
            member: true,
            vendor: true,
          },
        });

    return res.status(existingUser ? 200 : 201).json({
      user: serializeUser(user),
      defaultPassword: DEFAULT_SUPER_ADMIN_PASSWORD,
    });
  },
);

router.delete(
  "/:id",
  requireAuthenticatedSession,
  requireAdminUser,
  async (req, res) => {
    const targetUser = await prisma.user.findUnique({
      where: { id: req.params.id },
    });

    if (!targetUser) {
      return res.status(404).json({ error: "User not found" });
    }

    if (targetUser.id === req.auth.user.id) {
      return res.status(400).json({
        error: "You cannot delete the currently signed in account.",
      });
    }

    if (targetUser.isSuperAdmin && !req.auth.user.isSuperAdmin) {
      return res.status(403).json({
        error: "Only a super admin can delete another super admin.",
      });
    }

    if (targetUser.isSuperAdmin) {
      const superAdminCount = await prisma.user.count({
        where: {
          isSuperAdmin: true,
          isActive: true,
        },
      });

      if (superAdminCount <= 1) {
        return res.status(400).json({
          error: "At least one active super admin must remain.",
        });
      }
    }

    await prisma.user.delete({
      where: { id: targetUser.id },
    });

    return res.json({ success: true });
  },
);

export default router;
