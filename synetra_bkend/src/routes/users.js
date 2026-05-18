import { Router } from "express";
import prismaPkg from "@prisma/client";
import { z } from "zod";
import { buildDefaultMemberPasswordHash } from "../lib/auth.js";
import { prisma } from "../lib/prisma.js";

const router = Router();
const { ApprovalStatus, MemberStatus } = prismaPkg;

const accessStatusSchema = z.object({
  accessStatus: z.enum(["PENDING", "APPROVED", "SUSPENDED", "CANCELLED"]),
});

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

router.get("/", async (req, res) => {
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

  res.json({ users });
});

router.patch("/:id/access", async (req, res) => {
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

  const { user: userData, memberStatus } = buildAccessUpdate(parsed.data.accessStatus);

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

  return res.json({ user: updatedUser });
});

export default router;
