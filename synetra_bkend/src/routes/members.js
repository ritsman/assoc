import fs from "fs";
import path from "path";
import multer from "multer";
import { Router } from "express";
import prismaPkg from "@prisma/client";
import xlsx from "xlsx";
import { z } from "zod";
import {
  BULK_MEMBER_DEFAULT_PASSWORD,
  PENDING_PASSWORD_PREFIX,
  buildDefaultMemberPasswordHash,
  buildPendingPasswordHash,
} from "../lib/auth.js";
import {
  buildPublicThumbnailUrl,
  resolvePublicAssetUrl,
} from "../lib/public-url.js";
import {
  deleteLocalAssetIfPresent,
  isInlineDataImageUrl,
  persistInlineImageDataUrl,
} from "../lib/inline-image-assets.js";
import { ensureAssociationAppAccess } from "../lib/app-access.js";
import { prisma } from "../lib/prisma.js";
import { getUploadSubdirPath } from "../lib/uploads-dir.js";

const router = Router();
const { ApprovalStatus, MemberStatus, PaymentStatus, Prisma } = prismaPkg;
const currentDirPath = path.dirname(new URL(import.meta.url).pathname);
const bulkMemberUploadsDirPath = getUploadSubdirPath("member-imports");
const memberPhotoUploadsDirPath = getUploadSubdirPath("member-photos");
const optionalDateField = z.preprocess(
  (value) => (value === "" ? null : value),
  z.coerce.date().nullable().optional(),
);

const accessStatusSchema = z.object({
  accessStatus: z.enum(["PENDING", "APPROVED", "SUSPENDED", "CANCELLED"]),
});
const memberViewQuerySchema = z.enum(["legacy", "directory", "admin"]);

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

const bulkImportUpload = multer({
  storage: multer.diskStorage({
    destination: (_req, _file, callback) => {
      fs.mkdirSync(bulkMemberUploadsDirPath, { recursive: true });
      callback(null, bulkMemberUploadsDirPath);
    },
    filename: (_req, file, callback) => {
      const safeName = path
        .basename(file.originalname, path.extname(file.originalname))
        .replace(/[^a-zA-Z0-9-_]+/g, "-")
        .replace(/^-+|-+$/g, "")
        .slice(0, 60);
      callback(null, `${Date.now()}-${safeName || "bulk-members"}${path.extname(file.originalname)}`);
    },
  }),
  limits: {
    fileSize: 5 * 1024 * 1024,
  },
  fileFilter: (_req, file, callback) => {
    const isExcelMime =
      file.mimetype ===
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" ||
      file.mimetype === "application/vnd.ms-excel";
    const ext = path.extname(file.originalname).toLowerCase();

    if (!isExcelMime && ext !== ".xlsx" && ext !== ".xls") {
      callback(new Error("Bulk member import only supports Excel files."));
      return;
    }

    callback(null, true);
  },
});

function normalizeExcelValue(value) {
  if (value === null || value === undefined) {
    return "";
  }

  if (value instanceof Date) {
    return value.toISOString().slice(0, 10);
  }

  if (typeof value === "number") {
    return Number.isInteger(value) ? String(value) : String(value).trim();
  }

  return String(value).trim();
}

function splitRepresentativeName(name) {
  const cleaned = normalizeExcelValue(name).replace(/\s+/g, " ").trim();
  if (!cleaned) {
    return {
      firstName: "Member",
      lastName: "Imported",
    };
  }

  const parts = cleaned.split(" ").filter(Boolean);
  return {
    firstName: parts[0] || "Member",
    lastName: parts.slice(1).join(" ") || "Imported",
  };
}

function mapBulkImportRow(headers, rowValues) {
  const row = Object.fromEntries(
    headers.map((header, index) => [header, normalizeExcelValue(rowValues[index])]),
  );

  const email = row.email?.toLowerCase();
  const representative = splitRepresentativeName(row.representative_name);

  return {
    membershipNumber: row.membership_no,
    companyName: row.company_name,
    midcArea: row.midc_area,
    representativeName: `${representative.firstName} ${representative.lastName}`.trim(),
    firstName: representative.firstName,
    lastName: representative.lastName,
    phone: row.cell_no,
    email,
    website: row.website,
    dateOfBirth: row.date_of_birth,
    gender: row.gender,
    bloodGroup: row.blood_group,
    businessType: row.business_type,
    address: row.address,
  };
}

function buildBulkCustomFieldValues(mappedRow) {
  return Object.fromEntries(
    Object.entries({
      membershipNumber: mappedRow.membershipNumber,
      midcArea: mappedRow.midcArea,
      representativeName: mappedRow.representativeName,
      website: mappedRow.website,
      dateOfBirth: mappedRow.dateOfBirth,
      gender: mappedRow.gender,
      bloodGroup: mappedRow.bloodGroup,
      businessType: mappedRow.businessType,
    }).filter(([, value]) => value),
  );
}

function isDuplicateMemberEmailError(error) {
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

function hasPendingPasswordHash(passwordHash) {
  return typeof passwordHash === "string" &&
    passwordHash.startsWith(`${PENDING_PASSWORD_PREFIX}:`);
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

function normalizeMemberPhotoValue(photoUrl, fallbackBaseName) {
  return persistInlineImageDataUrl({
    dataUrl: photoUrl,
    uploadsDirPath: memberPhotoUploadsDirPath,
    publicPathPrefix: "uploads/member-photos",
    fallbackBaseName,
  });
}

async function normalizeMemberRecord(member) {
  if (!member?.id || !isInlineDataImageUrl(member.photoUrl)) {
    return member;
  }

  const nextPhotoUrl = normalizeMemberPhotoValue(member.photoUrl, member.id);
  if (nextPhotoUrl === member.photoUrl) {
    return member;
  }

  return prisma.member.update({
    where: { id: member.id },
    data: { photoUrl: nextPhotoUrl },
    include: {
      association: true,
      user: true,
    },
  });
}

function serializeMemberUser(user) {
  if (!user) {
    return null;
  }

  const { passwordHash, ...safeUser } = user;
  return safeUser;
}

function serializeMemberAssociation(association) {
  if (!association) {
    return null;
  }

  return association;
}

function serializeMember(req, member) {
  return {
    ...member,
    association: serializeMemberAssociation(member.association),
    user: serializeMemberUser(member.user),
    photoUrl: resolvePublicAssetUrl(req, member.photoUrl),
    thumbnailUrl: buildPublicThumbnailUrl(req, member.photoUrl),
  };
}

function serializeMemberDirectoryItem(req, member) {
  return {
    id: member.id,
    associationId: member.associationId,
    firstName: member.firstName,
    lastName: member.lastName,
    email: member.email,
    phone: member.phone,
    address: member.address,
    gst: member.gst,
    photoUrl: resolvePublicAssetUrl(req, member.photoUrl),
    thumbnailUrl: buildPublicThumbnailUrl(req, member.photoUrl),
    companyName: member.companyName,
    roleTitle: member.roleTitle,
    committeePost: member.committeePost,
    committeeTenureStart: member.committeeTenureStart,
    committeeTenureEnd: member.committeeTenureEnd,
    memberBio: member.memberBio,
    membershipDetails: member.membershipDetails,
    membershipStartDate: member.membershipStartDate,
    membershipEndDate: member.membershipEndDate,
    paymentAmount: member.paymentAmount,
    paymentStatus: member.paymentStatus,
  };
}

function serializeMemberAdminItem(req, member) {
  return {
    id: member.id,
    associationId: member.associationId,
    firstName: member.firstName,
    lastName: member.lastName,
    email: member.email,
    phone: member.phone,
    photoUrl: resolvePublicAssetUrl(req, member.photoUrl),
    thumbnailUrl: buildPublicThumbnailUrl(req, member.photoUrl),
    companyName: member.companyName,
    roleTitle: member.roleTitle,
    user: member.user
      ? {
          approvalStatus: member.user.approvalStatus,
          isActive: member.user.isActive,
        }
      : null,
  };
}

router.get("/", async (req, res) => {
  const { associationId } = req.query;
  const parsedView = memberViewQuerySchema.safeParse(req.query.view);
  const view = parsedView.success ? parsedView.data : "legacy";
  const where = {
    ...(associationId ? { associationId: String(associationId) } : {}),
  };

  if (view === "directory") {
    const members = await prisma.member.findMany({
      where,
      select: {
        id: true,
        associationId: true,
        firstName: true,
        lastName: true,
        email: true,
        phone: true,
        address: true,
        gst: true,
        photoUrl: true,
        companyName: true,
        roleTitle: true,
        committeePost: true,
        committeeTenureStart: true,
        committeeTenureEnd: true,
        memberBio: true,
        membershipDetails: true,
        membershipStartDate: true,
        membershipEndDate: true,
        paymentAmount: true,
        paymentStatus: true,
      },
      orderBy: { createdAt: "desc" },
    });

    const normalizedMembers = await Promise.all(
      members.map(normalizeMemberRecord),
    );

    return res.json({
      members: normalizedMembers.map((member) =>
        serializeMemberDirectoryItem(req, member),
      ),
    });
  }

  if (view === "admin") {
    const members = await prisma.member.findMany({
      where,
      select: {
        id: true,
        associationId: true,
        firstName: true,
        lastName: true,
        email: true,
        phone: true,
        photoUrl: true,
        companyName: true,
        roleTitle: true,
        user: {
          select: {
            approvalStatus: true,
            isActive: true,
          },
        },
      },
      orderBy: { createdAt: "desc" },
    });

    const normalizedMembers = await Promise.all(
      members.map(normalizeMemberRecord),
    );

    return res.json({
      members: normalizedMembers.map((member) =>
        serializeMemberAdminItem(req, member),
      ),
    });
  }

  const members = await prisma.member.findMany({
    where,
    include: {
      association: true,
      user: true,
    },
    orderBy: { createdAt: "desc" },
  });

  const normalizedMembers = await Promise.all(
    members.map(normalizeMemberRecord),
  );

  return res.json({
    members: normalizedMembers.map((member) => serializeMember(req, member)),
  });
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
  const appAccess = await ensureAssociationAppAccess(associationId);
  const initialApprovalStatus =
    appAccess.approveRegistrationRequest === false
      ? ApprovalStatus.APPROVED
      : ApprovalStatus.PENDING;
  const initialMembershipStatus =
    appAccess.approveMembership === false
      ? MemberStatus.ACTIVE
      : (parsed.data.membershipStatus ?? MemberStatus.PENDING);
  const initialApprovedAt =
    initialApprovalStatus === ApprovalStatus.APPROVED ? new Date() : null;
  const initialPasswordHash =
    initialApprovalStatus === ApprovalStatus.APPROVED
      ? await buildDefaultMemberPasswordHash()
      : buildPendingPasswordHash();

  try {
    const member = await prisma.$transaction(async (tx) => {
      const createdMember = await tx.member.create({
        data: {
          ...parsed.data,
          photoUrl: normalizeMemberPhotoValue(
            parsed.data.photoUrl,
            parsed.data.email || "member-photo",
          ),
          associationId,
          membershipStatus: initialMembershipStatus,
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
        const shouldAssignDefaultPassword =
          initialApprovalStatus === ApprovalStatus.APPROVED &&
          (existingUser.approvalStatus !== ApprovalStatus.APPROVED ||
            hasPendingPasswordHash(existingUser.passwordHash));

        await tx.user.update({
          where: { id: existingUser.id },
          data: {
            ...buildMemberUserPayload(createdMember),
            approvalStatus:
              existingUser.approvalStatus === ApprovalStatus.REJECTED ||
                  existingUser.approvalStatus !== initialApprovalStatus
                ? initialApprovalStatus
                : undefined,
            approvedAt:
              existingUser.approvalStatus === ApprovalStatus.REJECTED ||
                  initialApprovalStatus === ApprovalStatus.APPROVED
                ? initialApprovedAt
                : undefined,
            rejectedAt:
              existingUser.approvalStatus === ApprovalStatus.REJECTED
                ? null
                : undefined,
            ...(shouldAssignDefaultPassword
              ? { passwordHash: initialPasswordHash }
              : {}),
          },
        });
      } else {
        await tx.user.create({
          data: {
            ...buildMemberUserPayload(createdMember),
            passwordHash: initialPasswordHash,
            approvalStatus: initialApprovalStatus,
            approvedAt: initialApprovedAt,
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

    return res.status(201).json({ member: serializeMember(req, member) });
  } catch (error) {
    if (isDuplicateMemberEmailError(error)) {
      return res.status(409).json({
        error: "A member with this email already exists in the association",
      });
    }

    throw error;
  }
});

router.post(
  "/bulk-import",
  bulkImportUpload.single("excelFile"),
  async (req, res) => {
    if (!req.file) {
      return res.status(400).json({ error: "Attach an Excel file to import members." });
    }

    try {
      const workbook = xlsx.readFile(req.file.path, {
        cellDates: true,
      });
      const sheetName = workbook.SheetNames[0];
      const sheet = workbook.Sheets[sheetName];

      if (!sheet) {
        return res.status(400).json({ error: "The Excel file does not contain a readable sheet." });
      }

      const rows = xlsx.utils.sheet_to_json(sheet, {
        header: 1,
        defval: "",
        raw: false,
      });

      if (rows.length < 2) {
        return res.status(400).json({ error: "The Excel file does not contain any member rows." });
      }

      const headers = rows[0].map((header) =>
        normalizeExcelValue(header)
          .toLowerCase()
          .replace(/[^a-z0-9]+/g, "_")
          .replace(/^_+|_+$/g, ""),
      );
      const associationId = await ensureAssociation();
      const imported = [];
      const skipped = [];

      for (let rowIndex = 1; rowIndex < rows.length; rowIndex += 1) {
        const values = rows[rowIndex];
        if (!Array.isArray(values)) {
          continue;
        }

        const mappedRow = mapBulkImportRow(headers, values);

        if (
          !mappedRow.companyName &&
          !mappedRow.representativeName &&
          !mappedRow.email
        ) {
          continue;
        }

        if (!mappedRow.email) {
          skipped.push({
            rowNumber: rowIndex + 1,
            reason: "Missing email",
            companyName: mappedRow.companyName,
          });
          continue;
        }

        try {
          const passwordHash = await buildDefaultMemberPasswordHash(
            BULK_MEMBER_DEFAULT_PASSWORD,
          );

          const member = await prisma.$transaction(async (tx) => {
            const existingMember = await tx.member.findFirst({
              where: {
                associationId,
                email: mappedRow.email,
              },
            });

            if (existingMember) {
              throw new Error("DUPLICATE_MEMBER");
            }

            const createdMember = await tx.member.create({
              data: {
                associationId,
                firstName: mappedRow.firstName,
                lastName: mappedRow.lastName,
                email: mappedRow.email,
                phone: mappedRow.phone || undefined,
                address: mappedRow.address || undefined,
                companyName: mappedRow.companyName || undefined,
                roleTitle: mappedRow.businessType || undefined,
                membershipDetails: mappedRow.membershipNumber
                  ? `Membership No: ${mappedRow.membershipNumber}`
                  : undefined,
                membershipStatus: MemberStatus.ACTIVE,
                paymentStatus: PaymentStatus.PENDING,
                customFieldValues: buildBulkCustomFieldValues(mappedRow),
              },
            });

            const existingUser = await tx.user.findUnique({
              where: { email: mappedRow.email },
            });

            if (existingUser) {
              await tx.user.update({
                where: { id: existingUser.id },
                data: {
                  ...buildMemberUserPayload(createdMember),
                  passwordHash,
                  approvalStatus: ApprovalStatus.APPROVED,
                  isActive: true,
                  approvedAt: new Date(),
                  rejectedAt: null,
                },
              });
            } else {
              await tx.user.create({
                data: {
                  ...buildMemberUserPayload(createdMember),
                  passwordHash,
                  approvalStatus: ApprovalStatus.APPROVED,
                  isActive: true,
                  approvedAt: new Date(),
                },
              });
            }

            return createdMember;
          });

          imported.push({
            rowNumber: rowIndex + 1,
            memberId: member.id,
            email: mappedRow.email,
            companyName: mappedRow.companyName,
          });
        } catch (error) {
          skipped.push({
            rowNumber: rowIndex + 1,
            email: mappedRow.email,
            companyName: mappedRow.companyName,
            reason:
              error instanceof Error && error.message === "DUPLICATE_MEMBER"
                ? "Duplicate member email in this association"
                : "Unable to import row",
          });
        }
      }

      return res.status(201).json({
        summary: {
          totalRows: rows.length - 1,
          importedCount: imported.length,
          skippedCount: skipped.length,
          defaultLoginPassword: BULK_MEMBER_DEFAULT_PASSWORD,
        },
        imported,
        skipped,
      });
    } finally {
      fs.unlink(req.file.path, () => {});
    }
  },
);

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

  try {
    const member = await prisma.$transaction(async (tx) => {
      const updatedMember = await tx.member.update({
        where: { id: req.params.id },
        data: {
          ...parsed.data,
          photoUrl: normalizeMemberPhotoValue(
            parsed.data.photoUrl,
            req.params.id,
          ),
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

    if (member.photoUrl !== existingMember.photoUrl) {
      deleteLocalAssetIfPresent(existingMember.photoUrl, "uploads/member-photos");
    }

    return res.json({ member: serializeMember(req, member) });
  } catch (error) {
    if (isDuplicateMemberEmailError(error)) {
      return res.status(409).json({
        error: "A member with this email already exists in the association",
      });
    }

    throw error;
  }
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
  const passwordHash =
    parsed.data.accessStatus === "APPROVED"
      ? await buildDefaultMemberPasswordHash()
      : undefined;

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
          ...(passwordHash ? { passwordHash } : {}),
        },
      });
    } else {
      await tx.user.create({
        data: {
          ...buildMemberUserPayload(member),
          ...userData,
          passwordHash: passwordHash ?? buildPendingPasswordHash(),
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

  return res.json({ member: serializeMember(req, updatedMember) });
});

router.delete("/:id", async (req, res) => {
  const deleted = await prisma.$transaction(async (tx) => {
    const member = await tx.member.findUnique({
      where: { id: req.params.id },
    });

    if (!member) {
      return false;
    }

    const linkedUser = await tx.user.findFirst({
      where: { memberId: req.params.id },
    });

    await tx.member.delete({
      where: { id: req.params.id },
    });

    if (!linkedUser) {
      return true;
    }

    if (linkedUser.isAdmin || linkedUser.isVendor) {
      await tx.user.update({
        where: { id: linkedUser.id },
        data: {
          isMember: false,
          memberId: null,
        },
      });
      return true;
    }

    await tx.user.delete({
      where: { id: linkedUser.id },
    });

    return true;
  });

  if (!deleted) {
    return res.status(404).json({ error: "Member not found" });
  }

  return res.status(204).send();
});

export default router;
