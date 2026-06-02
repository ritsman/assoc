import { Router } from "express";
import prismaPkg from "@prisma/client";
import { z } from "zod";
import { buildDefaultVendorPasswordHash } from "../lib/auth.js";
import { ensureAssociationAppAccess } from "../lib/app-access.js";
import { prisma } from "../lib/prisma.js";
import { syncVendorTaxonomyFromVendorInput } from "../lib/vendor-taxonomy.js";

const router = Router();
const { ApprovalStatus, PaymentStatus, Prisma, VendorStatus } = prismaPkg;

const optionalDateField = z.preprocess(
  (value) => (value === "" || value === null ? null : value),
  z.coerce.date().nullable().optional(),
);

const optionalEmailField = z.preprocess(
  (value) =>
    value === "" || value === null || typeof value === "undefined"
      ? undefined
      : String(value).trim().toLowerCase(),
  z.string().email().optional(),
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
  primaryLoginEmail: optionalEmailField,
  secondaryLoginEmail: optionalEmailField,
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
  const contactName = (
    vendor.contactPerson ||
    vendor.name ||
    vendor.companyName ||
    ""
  ).trim();
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

function buildVendorUserPayloadForEmail(vendor, email) {
  return {
    ...buildVendorUserPayload(vendor),
    email,
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

function buildLoginEmails(payload) {
  const emails = [
    payload.primaryLoginEmail || payload.email,
    payload.secondaryLoginEmail,
  ]
    .map((value) =>
      String(value || "")
        .trim()
        .toLowerCase(),
    )
    .filter(Boolean);

  if (emails.length === 0) {
    throw new Error("At least one vendor login email is required.");
  }

  if (new Set(emails).size !== emails.length) {
    throw new Error(
      "Primary and secondary vendor login emails must be different.",
    );
  }

  if (emails.length > 2) {
    throw new Error("Only two vendor login emails are allowed per vendor.");
  }

  return emails;
}

function accessStatusForVendorStatus(status) {
  switch (status) {
    case VendorStatus.ACTIVE:
      return "APPROVED";
    case VendorStatus.SUSPENDED:
      return "SUSPENDED";
    case VendorStatus.LAPSED:
      return "CANCELLED";
    case VendorStatus.PENDING:
    default:
      return "PENDING";
  }
}

function extractVendorData(payload, associationId) {
  const {
    primaryLoginEmail: _primaryLoginEmail,
    secondaryLoginEmail: _secondaryLoginEmail,
    ...vendorData
  } = payload;

  return {
    ...vendorData,
    ...(associationId ? { associationId } : {}),
  };
}

const vendorInclude = {
  association: true,
  users: true,
};

function serializeVendorUser(user) {
  const { passwordHash, ...safeUser } = user;
  return safeUser;
}

async function syncVendorUsers(tx, vendor, loginEmails) {
  if (loginEmails.length > 2) {
    throw new Error("Only two vendor login emails are allowed per vendor.");
  }

  const existingVendorUsers = await tx.user.findMany({
    where: { vendorId: vendor.id },
    orderBy: { createdAt: "asc" },
  });

  const usersByEmail = new Map(
    existingVendorUsers.map((user) => [user.email.toLowerCase(), user]),
  );
  const discoveredUsers = await tx.user.findMany({
    where: {
      OR: loginEmails.map((email) => ({
        email: {
          equals: email,
          mode: "insensitive",
        },
      })),
    },
  });

  for (const user of discoveredUsers) {
    usersByEmail.set(user.email.toLowerCase(), user);
  }

  const accessUpdate = buildAccessUpdate(
    accessStatusForVendorStatus(vendor.status),
  ).user;
  const desiredEmails = new Set(loginEmails);

  for (const email of loginEmails) {
    const existingUser = usersByEmail.get(email);

    if (existingUser?.vendorId && existingUser.vendorId !== vendor.id) {
      throw new Error(
        `The login email ${email} is already linked to another vendor account.`,
      );
    }

    if (existingUser && (existingUser.isAdmin || existingUser.isMember)) {
      throw new Error(
        `The login email ${email} already belongs to a member or admin account.`,
      );
    }

    const userPayload = buildVendorUserPayloadForEmail(vendor, email);

    if (existingUser) {
      await tx.user.update({
        where: { id: existingUser.id },
        data: {
          ...userPayload,
          ...accessUpdate,
          ...(existingUser.passwordHash?.startsWith("pending-password-setup:")
            ? { passwordHash: await buildDefaultVendorPasswordHash() }
            : {}),
          isActive: accessUpdate.isActive ?? true,
        },
      });
    } else {
      await tx.user.create({
        data: {
          ...userPayload,
          passwordHash: await buildDefaultVendorPasswordHash(),
          ...accessUpdate,
          isActive: accessUpdate.isActive ?? true,
        },
      });
    }
  }

  for (const user of existingVendorUsers) {
    if (desiredEmails.has(user.email.toLowerCase())) {
      continue;
    }

    if (user.isAdmin || user.isMember) {
      await tx.user.update({
        where: { id: user.id },
        data: {
          vendorId: null,
          isVendor: false,
        },
      });
    } else {
      await tx.user.delete({
        where: { id: user.id },
      });
    }
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
  const users = [...(vendor.users ?? [])].sort(
    (left, right) =>
      new Date(left.createdAt).getTime() - new Date(right.createdAt).getTime(),
  );
  return {
    ...vendor,
    users: users.map(serializeVendorUser),
    loginEmails: users.map((user) => user.email),
    primaryLoginEmail: users[0]?.email ?? "",
    secondaryLoginEmail: users[1]?.email ?? "",
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
    include: vendorInclude,
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
  const appAccess = await ensureAssociationAppAccess(associationId);
  const loginEmails = buildLoginEmails(parsed.data);

  try {
    const vendor = await prisma.$transaction(async (tx) => {
      const createdVendor = await tx.vendor.create({
        data: {
          ...extractVendorData(parsed.data, associationId),
          paymentStatus: parsed.data.paymentStatus ?? PaymentStatus.PENDING,
          status:
              parsed.data.status ??
              (appAccess.approveRegistrationRequest === false
                  ? VendorStatus.ACTIVE
                  : VendorStatus.PENDING),
        },
        include: vendorInclude,
      });

      await syncVendorTaxonomyFromVendorInput(
        tx,
        createdVendor.associationId,
        createdVendor.category,
        createdVendor.vendorType,
      );
      await syncVendorUsers(tx, createdVendor, loginEmails);

      return tx.vendor.findUnique({
        where: { id: createdVendor.id },
        include: vendorInclude,
      });
    });

    return res.status(201).json({ vendor: serializeVendor(vendor) });
  } catch (error) {
    if (isDuplicateVendorEmailError(error)) {
      return res.status(409).json({
        error: "A vendor with this email already exists in the association",
      });
    }

    if (
      error instanceof Error &&
      (error.message.includes("linked to another vendor") ||
        error.message.includes("Only two vendor login emails") ||
        error.message.includes("vendor login emails") ||
        error.message.includes("already belongs to a member or admin"))
    ) {
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
    include: vendorInclude,
  });

  if (!existingVendor) {
    return res.status(404).json({ error: "Vendor not found" });
  }

  try {
    const sortedExistingUsers = [...(existingVendor.users ?? [])].sort(
      (left, right) =>
        new Date(left.createdAt).getTime() -
        new Date(right.createdAt).getTime(),
    );
    const loginEmails = buildLoginEmails({
      ...existingVendor,
      primaryLoginEmail:
        typeof parsed.data.primaryLoginEmail === "undefined"
          ? sortedExistingUsers[0]?.email || existingVendor.email
          : parsed.data.primaryLoginEmail,
      secondaryLoginEmail:
        typeof parsed.data.secondaryLoginEmail === "undefined"
          ? sortedExistingUsers[1]?.email || ""
          : parsed.data.secondaryLoginEmail,
      email: parsed.data.email ?? existingVendor.email,
    });

    const updatedVendor = await prisma.$transaction(async (tx) => {
      const nextVendor = await tx.vendor.update({
        where: { id: req.params.id },
        data: extractVendorData(parsed.data),
        include: vendorInclude,
      });

      await syncVendorTaxonomyFromVendorInput(
        tx,
        nextVendor.associationId,
        nextVendor.category,
        nextVendor.vendorType,
      );
      await syncVendorUsers(tx, nextVendor, loginEmails);

      return tx.vendor.findUnique({
        where: { id: req.params.id },
        include: vendorInclude,
      });
    });

    return res.json({ vendor: serializeVendor(updatedVendor) });
  } catch (error) {
    if (isDuplicateVendorEmailError(error)) {
      return res.status(409).json({
        error: "A vendor with this email already exists in the association",
      });
    }

    if (
      error instanceof Error &&
      (error.message.includes("linked to another vendor") ||
        error.message.includes("Only two vendor login emails") ||
        error.message.includes("vendor login emails") ||
        error.message.includes("already belongs to a member or admin"))
    ) {
      return res.status(409).json({
        error: error.message,
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
    include: vendorInclude,
  });

  if (!vendor) {
    return res.status(404).json({ error: "Vendor not found" });
  }

  const { user: userData, vendorStatus } = buildAccessUpdate(
    parsed.data.accessStatus,
  );

  const updatedVendor = await prisma.$transaction(async (tx) => {
    const nextVendor = await tx.vendor.update({
      where: { id: req.params.id },
      data: {
        status: vendorStatus,
      },
      include: vendorInclude,
    });

    if ((nextVendor.users ?? []).length > 0) {
      await tx.user.updateMany({
        where: { vendorId: nextVendor.id },
        data: userData,
      });
    }

    return tx.vendor.findUnique({
      where: { id: req.params.id },
      include: vendorInclude,
    });
  });

  return res.json({ vendor: serializeVendor(updatedVendor) });
});

router.delete("/:id", async (req, res) => {
  const existingVendor = await prisma.vendor.findUnique({
    where: { id: req.params.id },
    include: vendorInclude,
  });

  if (!existingVendor) {
    return res.status(404).json({ error: "Vendor not found" });
  }

  await prisma.$transaction(async (tx) => {
    for (const linkedUser of existingVendor.users ?? []) {
      if (linkedUser.isAdmin || linkedUser.isMember) {
        await tx.user.update({
          where: { id: linkedUser.id },
          data: {
            vendorId: null,
            isVendor: false,
          },
        });
      } else {
        await tx.user.delete({
          where: { id: linkedUser.id },
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
