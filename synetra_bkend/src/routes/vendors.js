import { Router } from "express";
import prismaPkg from "@prisma/client";
import { z } from "zod";
import { buildPendingPasswordHash } from "../lib/auth.js";
import { prisma } from "../lib/prisma.js";

const router = Router();
const { ApprovalStatus, PaymentStatus, Prisma, VendorStatus } = prismaPkg;

const optionalDateField = z.preprocess(
  (value) => (value === "" || value === null ? null : value),
  z.coerce.date().nullable().optional(),
);

const accessStatusSchema = z.object({
  accessStatus: z.enum(["PENDING", "APPROVED", "SUSPENDED", "CANCELLED"]),
});

const vendorSchema = z.object({
  associationId: z.string().min(1).optional(),
  name: z.string().min(1),
  companyName: z.string().min(1),
  contactPerson: z.string().optional(),
  email: z.string().email(),
  phone: z.string().optional(),
  whatsapp: z.string().optional(),
  address: z.string().optional(),
  city: z.string().optional(),
  vendorType: z.string().optional(),
  category: z.string().optional(),
  facebookUrl: z.string().optional(),
  instagramUrl: z.string().optional(),
  youtubeUrl: z.string().optional(),
  linkedinUrl: z.string().optional(),
  xUrl: z.string().optional(),
  onboardingStartAt: optionalDateField,
  onboardingEndAt: optionalDateField,
  membershipPlan: z.string().optional(),
  paymentStatus: z.nativeEnum(PaymentStatus).optional(),
  paymentAmount: z.string().optional(),
  paymentDueDate: optionalDateField,
  badge: z.string().optional(),
  notes: z.string().optional(),
  status: z.nativeEnum(VendorStatus).optional(),
});

const vendorUpdateSchema = vendorSchema.partial();

function isDuplicateVendorEmailError(error) {
  if (!(error instanceof Prisma.PrismaClientKnownRequestError)) {
    return false;
  }

  if (error.code !== "P2002") {
    return false;
  }

  const target = Array.isArray(error.meta?.target)
    ? error.meta.target
    : [error.meta?.target].filter(Boolean);

  return target.includes("associationId") && target.includes("email");
}

function buildVendorUserPayload(vendor) {
  const contactName = (vendor.contactPerson || vendor.name || vendor.companyName || "").trim();
  const [firstName, ...restNameParts] = contactName.split(" ").filter(Boolean);

  return {
    associationId: vendor.associationId,
    vendorId: vendor.id,
    firstName: firstName || vendor.name || vendor.companyName,
    lastName: restNameParts.join(" "),
    email: vendor.email,
    phone: vendor.phone,
    isVendor: true,
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
        vendorStatus: VendorStatus.ACTIVE,
      };
    case "SUSPENDED":
      return {
        user: {
          approvalStatus: ApprovalStatus.APPROVED,
          isActive: false,
        },
        vendorStatus: VendorStatus.SUSPENDED,
      };
    case "CANCELLED":
      return {
        user: {
          approvalStatus: ApprovalStatus.REJECTED,
          isActive: false,
          approvedAt: null,
          rejectedAt: new Date(),
        },
        vendorStatus: VendorStatus.LAPSED,
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
        vendorStatus: VendorStatus.PENDING,
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

function formatRangeDate(date) {
  if (!date) {
    return "";
  }

  return date.toISOString().slice(0, 10);
}

function serializeVendor(vendor) {
  return {
    ...vendor,
    onboardingStartAt: formatRangeDate(vendor.onboardingStartAt),
    onboardingEndAt: formatRangeDate(vendor.onboardingEndAt),
    paymentDueDate: formatRangeDate(vendor.paymentDueDate),
  };
}

router.get("/", async (req, res) => {
  const { associationId } = req.query;

  const vendors = await prisma.vendor.findMany({
    where: {
      ...(associationId ? { associationId: String(associationId) } : {}),
    },
    include: {
      association: true,
      user: true,
    },
    orderBy: { createdAt: "desc" },
  });

  return res.json({ vendors: vendors.map(serializeVendor) });
});

router.post("/", async (req, res) => {
  const parsed = vendorSchema.safeParse(req.body);

  if (!parsed.success) {
    return res.status(400).json({
      error: "Invalid vendor payload",
      details: parsed.error.flatten(),
    });
  }

  const associationId = await ensureAssociation(parsed.data.associationId);

  try {
    const vendor = await prisma.$transaction(async (tx) => {
      const createdVendor = await tx.vendor.create({
        data: {
          ...parsed.data,
          associationId,
          paymentStatus: parsed.data.paymentStatus ?? PaymentStatus.PENDING,
          status: parsed.data.status ?? VendorStatus.PENDING,
        },
        include: {
          association: true,
          user: true,
        },
      });

      const existingUser = await tx.user.findUnique({
        where: { email: createdVendor.email },
      });

      if (existingUser?.vendorId && existingUser.vendorId !== createdVendor.id) {
        throw new Error("This email is already linked to another vendor account");
      }

      if (existingUser) {
        await tx.user.update({
          where: { id: existingUser.id },
          data: {
            ...buildVendorUserPayload(createdVendor),
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
            isActive: true,
          },
        });
      } else {
        await tx.user.create({
          data: {
            ...buildVendorUserPayload(createdVendor),
            passwordHash: buildPendingPasswordHash(),
            approvalStatus: ApprovalStatus.PENDING,
            isActive: true,
          },
        });
      }

      return tx.vendor.findUnique({
        where: { id: createdVendor.id },
        include: {
          association: true,
          user: true,
        },
      });
    });

    return res.status(201).json({ vendor: serializeVendor(vendor) });
  } catch (error) {
    if (isDuplicateVendorEmailError(error)) {
      return res.status(409).json({
        error: "A vendor with this email already exists in the association",
      });
    }

    if (error instanceof Error && error.message.includes("linked to another vendor")) {
      return res.status(409).json({
        error: error.message,
      });
    }

    throw error;
  }
});

router.patch("/:id", async (req, res) => {
  const parsed = vendorUpdateSchema.safeParse(req.body);

  if (!parsed.success) {
    return res.status(400).json({
      error: "Invalid vendor payload",
      details: parsed.error.flatten(),
    });
  }

  const existingVendor = await prisma.vendor.findUnique({
    where: { id: req.params.id },
    include: { user: true },
  });

  if (!existingVendor) {
    return res.status(404).json({ error: "Vendor not found" });
  }

  try {
    const updatedVendor = await prisma.$transaction(async (tx) => {
      const nextVendor = await tx.vendor.update({
        where: { id: req.params.id },
        data: parsed.data,
        include: {
          association: true,
          user: true,
        },
      });

      const linkedUser = nextVendor.user;
      if (linkedUser) {
        await tx.user.update({
          where: { id: linkedUser.id },
          data: buildVendorUserPayload(nextVendor),
        });
      }

      return tx.vendor.findUnique({
        where: { id: req.params.id },
        include: {
          association: true,
          user: true,
        },
      });
    });

    return res.json({ vendor: serializeVendor(updatedVendor) });
  } catch (error) {
    if (isDuplicateVendorEmailError(error)) {
      return res.status(409).json({
        error: "A vendor with this email already exists in the association",
      });
    }

    throw error;
  }
});

router.patch("/:id/access", async (req, res) => {
  const parsed = accessStatusSchema.safeParse(req.body);

  if (!parsed.success) {
    return res.status(400).json({
      error: "Invalid vendor access payload",
      details: parsed.error.flatten(),
    });
  }

  const vendor = await prisma.vendor.findUnique({
    where: { id: req.params.id },
    include: { user: true },
  });

  if (!vendor) {
    return res.status(404).json({ error: "Vendor not found" });
  }

  const { user: userData, vendorStatus } = buildAccessUpdate(parsed.data.accessStatus);

  const updatedVendor = await prisma.$transaction(async (tx) => {
    const nextVendor = await tx.vendor.update({
      where: { id: req.params.id },
      data: {
        status: vendorStatus,
      },
      include: {
        association: true,
        user: true,
      },
    });

    if (nextVendor.user) {
      await tx.user.update({
        where: { id: nextVendor.user.id },
        data: userData,
      });
    }

    return tx.vendor.findUnique({
      where: { id: req.params.id },
      include: {
        association: true,
        user: true,
      },
    });
  });

  return res.json({ vendor: serializeVendor(updatedVendor) });
});

router.delete("/:id", async (req, res) => {
  const existingVendor = await prisma.vendor.findUnique({
    where: { id: req.params.id },
    include: { user: true },
  });

  if (!existingVendor) {
    return res.status(404).json({ error: "Vendor not found" });
  }

  await prisma.$transaction(async (tx) => {
    if (existingVendor.user) {
      if (existingVendor.user.isAdmin || existingVendor.user.isMember) {
        await tx.user.update({
          where: { id: existingVendor.user.id },
          data: {
            vendorId: null,
            isVendor: false,
          },
        });
      } else {
        await tx.user.delete({
          where: { id: existingVendor.user.id },
        });
      }
    }

    await tx.vendor.delete({
      where: { id: req.params.id },
    });
  });

  return res.status(204).send();
});

export default router;
