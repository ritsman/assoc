import { Router } from "express";
import { randomUUID } from "crypto";
import prismaPkg from "@prisma/client";
import { z } from "zod";
import { prisma } from "../lib/prisma.js";

const router = Router();
const { ApprovalStatus, MemberStatus, PaymentStatus } = prismaPkg;
const PENDING_PASSWORD_PREFIX = "pending-password-setup";
const optionalDateField = z.preprocess(
  (value) => (value === "" ? null : value),
  z.coerce.date().nullable().optional(),
);

const accessStatusSchema = z.object({
  accessStatus: z.enum(["PENDING", "APPROVED", "SUSPENDED", "CANCELLED"]),
});

const memberSchema = z.object({
  associationId: z.string().min(1).optional(),
  firstName: z.string().min(1),
  lastName: z.string().min(1),
  email: z.string().email(),
  phone: z.string().optional(),
  address: z.string().optional(),
  gst: z.string().optional(),
  photoUrl: z.string().optional(),
  companyName: z.string().optional(),
  roleTitle: z.string().optional(),
  specialization: z.string().optional(),
  committeePost: z.string().optional(),
  committeeTenureStart: optionalDateField,
  committeeTenureEnd: optionalDateField,
  memberBio: z.string().optional(),
  membershipDetails: z.string().optional(),
  membershipStartDate: optionalDateField,
  membershipEndDate: optionalDateField,
  paymentAmount: z.string().optional(),
  paymentStatus: z.nativeEnum(PaymentStatus).optional(),
  customFieldValues: z.record(z.string(), z.string()).optional(),
  membershipStatus: z.nativeEnum(MemberStatus).optional(),
});

const memberUpdateSchema = memberSchema.partial();

function buildPendingPasswordHash() {
  return `${PENDING_PASSWORD_PREFIX}:${randomUUID()}`;
}

function buildMemberUserPayload(member) {
  return {
    associationId: member.associationId,
    memberId: member.id,
    firstName: member.firstName,
    lastName: member.lastName,
    email: member.email,
    phone: member.phone,
    isMember: true,
    isActive: true,
  };
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

async function ensureAssociation(associationId) {
  if (associationId) {
    return associationId;
  }

  const existingAssociation = await prisma.association.findFirst({
    orderBy: { createdAt: "asc" },
  });

  if (existingAssociation) {
    return existingAssociation.id;
  }

  const defaultAssociation = await prisma.association.create({
    data: {
      name: "Association 1",
      slug: "association-1",
      appName: "Synetra",
      isActive: true,
    },
  });

  return defaultAssociation.id;
}

router.get("/", async (req, res) => {
  const { associationId } = req.query;

  const members = await prisma.member.findMany({
    where: {
      ...(associationId ? { associationId: String(associationId) } : {}),
    },
    include: {
      association: true,
      user: true,
    },
    orderBy: { createdAt: "desc" },
  });

  res.json({ members });
});

router.post("/", async (req, res) => {
  const parsed = memberSchema.safeParse(req.body);

  if (!parsed.success) {
    return res.status(400).json({
      error: "Invalid member payload",
      details: parsed.error.flatten(),
    });
  }

  const associationId = await ensureAssociation(parsed.data.associationId);

  const member = await prisma.$transaction(async (tx) => {
    const createdMember = await tx.member.create({
      data: {
        ...parsed.data,
        associationId,
        membershipStatus: parsed.data.membershipStatus ?? MemberStatus.PENDING,
      },
      include: {
        association: true,
        user: true,
      },
    });

    const existingUser = await tx.user.findUnique({
      where: { email: createdMember.email },
    });

    if (existingUser) {
      await tx.user.update({
        where: { id: existingUser.id },
        data: {
          ...buildMemberUserPayload(createdMember),
          approvalStatus:
            existingUser.approvalStatus === ApprovalStatus.REJECTED
              ? ApprovalStatus.PENDING
              : undefined,
          approvedAt:
            existingUser.approvalStatus === ApprovalStatus.REJECTED
              ? null
              : undefined,
          rejectedAt:
            existingUser.approvalStatus === ApprovalStatus.REJECTED
              ? null
              : undefined,
        },
      });
    } else {
      await tx.user.create({
        data: {
          ...buildMemberUserPayload(createdMember),
          passwordHash: buildPendingPasswordHash(),
          approvalStatus: ApprovalStatus.PENDING,
        },
      });
    }

    return tx.member.findUnique({
      where: { id: createdMember.id },
      include: {
        association: true,
        user: true,
      },
    });
  });

  return res.status(201).json({ member });
});

router.patch("/:id", async (req, res) => {
  const parsed = memberUpdateSchema.safeParse(req.body);

  if (!parsed.success) {
    return res.status(400).json({
      error: "Invalid member payload",
      details: parsed.error.flatten(),
    });
  }

  const associationId =
    parsed.data.associationId === undefined
      ? undefined
      : await ensureAssociation(parsed.data.associationId);

  const existingMember = await prisma.member.findUnique({
    where: { id: req.params.id },
  });

  if (!existingMember) {
    return res.status(404).json({ error: "Member not found" });
  }

  const member = await prisma.$transaction(async (tx) => {
    const updatedMember = await tx.member.update({
      where: { id: req.params.id },
      data: {
        ...parsed.data,
        ...(associationId ? { associationId } : {}),
      },
      include: {
        association: true,
        user: true,
      },
    });

    const linkedUser = await tx.user.findFirst({
      where: { memberId: updatedMember.id },
    });

    if (linkedUser) {
      await tx.user.update({
        where: { id: linkedUser.id },
        data: buildMemberUserPayload(updatedMember),
      });
    } else {
      const userByEmail = await tx.user.findUnique({
        where: { email: existingMember.email },
      });

      if (userByEmail) {
        await tx.user.update({
          where: { id: userByEmail.id },
          data: buildMemberUserPayload(updatedMember),
        });
      } else {
        await tx.user.create({
          data: {
            ...buildMemberUserPayload(updatedMember),
            passwordHash: buildPendingPasswordHash(),
            approvalStatus: ApprovalStatus.PENDING,
          },
        });
      }
    }

    return tx.member.findUnique({
      where: { id: updatedMember.id },
      include: {
        association: true,
        user: true,
      },
    });
  });

  return res.json({ member });
});

router.patch("/:id/access", async (req, res) => {
  const parsed = accessStatusSchema.safeParse(req.body);

  if (!parsed.success) {
    return res.status(400).json({
      error: "Invalid member access payload",
      details: parsed.error.flatten(),
    });
  }

  const member = await prisma.member.findUnique({
    where: { id: req.params.id },
  });

  if (!member) {
    return res.status(404).json({ error: "Member not found" });
  }

  const { user: userData, memberStatus } = buildAccessUpdate(parsed.data.accessStatus);

  const updatedMember = await prisma.$transaction(async (tx) => {
    const linkedUser =
      (await tx.user.findFirst({
        where: { memberId: member.id },
      })) ??
      (await tx.user.findUnique({
        where: { email: member.email },
      }));

    if (linkedUser) {
      await tx.user.update({
        where: { id: linkedUser.id },
        data: {
          ...buildMemberUserPayload(member),
          ...userData,
        },
      });
    } else {
      await tx.user.create({
        data: {
          ...buildMemberUserPayload(member),
          ...userData,
          passwordHash: buildPendingPasswordHash(),
        },
      });
    }

    await tx.member.update({
      where: { id: member.id },
      data: {
        membershipStatus: memberStatus,
      },
    });

    return tx.member.findUnique({
      where: { id: member.id },
      include: {
        association: true,
        user: true,
      },
    });
  });

  return res.json({ member: updatedMember });
});

router.delete("/:id", async (req, res) => {
  await prisma.$transaction(async (tx) => {
    const linkedUser = await tx.user.findFirst({
      where: { memberId: req.params.id },
    });

    await tx.member.delete({
      where: { id: req.params.id },
    });

    if (!linkedUser) {
      return;
    }

    if (linkedUser.isAdmin || linkedUser.isVendor) {
      await tx.user.update({
        where: { id: linkedUser.id },
        data: {
          isMember: false,
          memberId: null,
        },
      });
      return;
    }

    await tx.user.delete({
      where: { id: linkedUser.id },
    });
  });

  return res.status(204).send();
});

export default router;
