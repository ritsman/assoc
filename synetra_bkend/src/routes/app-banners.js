import fs from "fs";
import path from "path";
import multer from "multer";
import { Router } from "express";
import prismaPkg from "@prisma/client";
import { fileURLToPath } from "url";
import { z } from "zod";
import { buildPublicAssetUrl, resolvePublicAssetUrl } from "../lib/public-url.js";
import { prisma } from "../lib/prisma.js";
import { getUploadSubdirPath } from "../lib/uploads-dir.js";

const router = Router();
const { PostReviewStatus } = prismaPkg;
const currentFilePath = fileURLToPath(import.meta.url);
const appBannerUploadsDirPath = getUploadSubdirPath("app-banners");
const maxAppBannerImageBytes = 1024 * 1024;
const maxAppBannerPdfBytes = 2 * 1024 * 1024;
const maxActiveAppBanners = 50;

const optionalDateField = z.preprocess(
  (value) => (value === "" || value === null ? undefined : value),
  z.coerce.date().optional(),
);
const optionalIndexField = z.preprocess(
  (value) => (value === "" || value === null ? undefined : Number(value)),
  z.number().int().min(1).max(50).optional(),
);

const appBannerSchema = z.object({
  associationId: z.string().min(1).optional(),
  vendorId: z.string().optional(),
  shortText: z.string().min(1),
  contactNumber: z.string().optional(),
  socialMediaUrl: z.string().optional(),
  reviewStatus: z.nativeEnum(PostReviewStatus).optional(),
});

const appBannerUpdateSchema = z.object({
  associationId: z.string().min(1).optional(),
  vendorId: z.string().optional(),
  shortText: z.string().min(1),
  contactNumber: z.string().optional(),
  socialMediaUrl: z.string().optional(),
});

const moderationSchema = z.object({
  reviewStatus: z.nativeEnum(PostReviewStatus),
  paymentReceived: z.boolean().optional(),
  paymentMode: z.string().optional(),
  paymentRemarks: z.string().optional(),
  displayStart: optionalDateField,
  displayEnd: optionalDateField,
  displayIndex: optionalIndexField,
});

const appBannerStorage = multer.diskStorage({
  destination: (_req, _file, callback) => {
    fs.mkdirSync(appBannerUploadsDirPath, { recursive: true });
    callback(null, appBannerUploadsDirPath);
  },
  filename: (_req, file, callback) => {
    const safeBaseName = path
      .basename(file.originalname, path.extname(file.originalname))
      .replace(/[^a-zA-Z0-9-_]+/g, "-")
      .replace(/^-+|-+$/g, "")
      .slice(0, 60);
    callback(
      null,
      `${Date.now()}-${safeBaseName || "app-banner-asset"}${path.extname(file.originalname)}`,
    );
  },
});

const appBannerUpload = multer({
  storage: appBannerStorage,
  limits: {
    fileSize: maxAppBannerPdfBytes,
  },
  fileFilter: (_req, file, callback) => {
    const isImage = file.mimetype.startsWith("image/");
    const isPdf = file.mimetype === "application/pdf";

    if (!isImage && !isPdf) {
      callback(new Error("App banner uploads only support image and PDF files."));
      return;
    }

    callback(null, true);
  },
});

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

function buildDefaultDisplayWindow(displayStart, displayEnd) {
  const resolvedStart = displayStart ?? new Date();

  if (displayEnd) {
    return {
      displayStart: resolvedStart,
      displayEnd,
    };
  }

  const resolvedEnd = new Date(resolvedStart);
  resolvedEnd.setDate(resolvedEnd.getDate() + 90);

  return {
    displayStart: resolvedStart,
    displayEnd: resolvedEnd,
  };
}

function serializeAppBanner(req, banner) {
  return {
    id: banner.id,
    associationId: banner.associationId,
    vendorId: banner.vendorId || "",
    vendorName: banner.vendor?.companyName || banner.vendor?.name || "",
    shortText: banner.shortText,
    contactNumber: banner.contactNumber || "",
    mediaUrl: resolvePublicAssetUrl(req, banner.mediaUrl),
    mediaType: banner.mediaType || "",
    brochureUrl: resolvePublicAssetUrl(req, banner.brochureUrl),
    brochureMimeType: banner.brochureMimeType || "",
    socialMediaUrl: banner.socialMediaUrl || "",
    reviewStatus: banner.reviewStatus,
    paymentReceived: Boolean(banner.paymentReceived),
    paymentMode: banner.paymentMode || "",
    paymentRemarks: banner.paymentRemarks || "",
    displayStart: banner.displayStart?.toISOString().slice(0, 10) ?? "",
    displayEnd: banner.displayEnd?.toISOString().slice(0, 10) ?? "",
    displayIndex: banner.displayIndex ?? null,
    postedOn: banner.createdAt.toISOString().slice(0, 10),
    createdAt: banner.createdAt,
    updatedAt: banner.updatedAt,
  };
}

async function applyAppBannerModeration(bannerId, updates) {
  const existingBanner = await prisma.appBanner.findUnique({
    where: { id: bannerId },
  });

  if (!existingBanner) {
    throw new Error("App banner not found");
  }

  const nextReviewStatus = updates.reviewStatus;
  const nextDisplayIndex =
    typeof updates.displayIndex === "number" ? updates.displayIndex : existingBanner.displayIndex;
  const shouldApprove = nextReviewStatus === PostReviewStatus.APPROVED;

  if (shouldApprove && !nextDisplayIndex) {
    throw new Error("Select a banner sequence from 1 to 50 before approving.");
  }

  const defaultDisplayWindow = shouldApprove
    ? buildDefaultDisplayWindow(
        updates.displayStart ?? existingBanner.displayStart ?? undefined,
        updates.displayEnd ?? existingBanner.displayEnd ?? undefined,
      )
    : {
        displayStart: updates.displayStart ?? existingBanner.displayStart ?? null,
        displayEnd: updates.displayEnd ?? existingBanner.displayEnd ?? null,
      };

  return prisma.$transaction(async (tx) => {
    if (shouldApprove && nextDisplayIndex) {
      await tx.appBanner.updateMany({
        where: {
          associationId: existingBanner.associationId,
          reviewStatus: PostReviewStatus.APPROVED,
          displayIndex: nextDisplayIndex,
          id: { not: existingBanner.id },
        },
        data: {
          reviewStatus: PostReviewStatus.ON_HOLD,
          displayIndex: null,
        },
      });
    }

    const updatedBanner = await tx.appBanner.update({
      where: { id: existingBanner.id },
      data: {
        reviewStatus: nextReviewStatus,
        paymentReceived:
          typeof updates.paymentReceived === "boolean"
            ? updates.paymentReceived
            : existingBanner.paymentReceived,
        paymentMode: updates.paymentMode ?? existingBanner.paymentMode,
        paymentRemarks: updates.paymentRemarks ?? existingBanner.paymentRemarks,
        displayStart: shouldApprove ? defaultDisplayWindow.displayStart : updates.displayStart,
        displayEnd: shouldApprove ? defaultDisplayWindow.displayEnd : updates.displayEnd,
        displayIndex: shouldApprove ? nextDisplayIndex : updates.displayIndex ?? existingBanner.displayIndex,
        approvedAt:
          shouldApprove ? existingBanner.approvedAt ?? new Date() : nextReviewStatus === PostReviewStatus.APPROVED ? existingBanner.approvedAt : null,
      },
    });

    const approvedBanners = await tx.appBanner.findMany({
      where: {
        associationId: existingBanner.associationId,
        reviewStatus: PostReviewStatus.APPROVED,
      },
      orderBy: [
        { approvedAt: "asc" },
        { createdAt: "asc" },
      ],
    });

    if (approvedBanners.length > maxActiveAppBanners) {
      const overflowBanners = approvedBanners.slice(0, approvedBanners.length - maxActiveAppBanners);
      const overflowIds = overflowBanners.map((banner) => banner.id).filter((id) => id !== updatedBanner.id);

      if (overflowIds.length > 0) {
        await tx.appBanner.updateMany({
          where: { id: { in: overflowIds } },
          data: {
            reviewStatus: PostReviewStatus.ON_HOLD,
            displayIndex: null,
          },
        });
      }
    }

    return tx.appBanner.findUnique({
      where: { id: existingBanner.id },
      include: { vendor: true },
    });
  });
}

function removeStoredAppBannerAsset(assetUrl) {
  const rawValue = String(assetUrl || "").trim();
  if (!rawValue) {
    return;
  }

  let relativePath = rawValue;

  if (/^https?:\/\//i.test(rawValue)) {
    try {
      relativePath = new URL(rawValue).pathname;
    } catch (_error) {
      return;
    }
  }

  const normalizedPath = relativePath.replace(/^\/+/, "");

  if (!normalizedPath.startsWith("uploads/app-banners/")) {
    return;
  }

  const absolutePath = path.join(path.dirname(currentFilePath), "../../", normalizedPath);

  if (fs.existsSync(absolutePath)) {
    fs.unlinkSync(absolutePath);
  }
}

router.get("/", async (req, res) => {
  const { associationId, vendorId } = req.query;

  const banners = await prisma.appBanner.findMany({
    where: {
      ...(associationId ? { associationId: String(associationId) } : {}),
      ...(vendorId ? { vendorId: String(vendorId) } : {}),
    },
    include: {
      vendor: true,
    },
    orderBy: [{ displayIndex: "asc" }, { createdAt: "desc" }],
  });

  return res.json({ banners: banners.map((banner) => serializeAppBanner(req, banner)) });
});

router.post(
  "/",
  appBannerUpload.fields([
    { name: "mediaFile", maxCount: 1 },
    { name: "brochureFile", maxCount: 1 },
  ]),
  async (req, res) => {
    const parsed = appBannerSchema.safeParse(req.body);

    if (!parsed.success) {
      return res.status(400).json({
        error: "Invalid app banner payload",
        details: parsed.error.flatten(),
      });
    }

    try {
      let vendorId = parsed.data.vendorId || null;
      let associationId = await ensureAssociation(parsed.data.associationId);

      if (vendorId) {
        const vendor = await prisma.vendor.findUnique({
          where: { id: vendorId },
        });

        if (!vendor) {
          return res.status(400).json({ error: "Selected vendor was not found." });
        }

        associationId = vendor.associationId;
      }

      const files = req.files || {};
      const mediaFile = Array.isArray(files.mediaFile) ? files.mediaFile[0] : null;
      const brochureFile = Array.isArray(files.brochureFile) ? files.brochureFile[0] : null;

      if (mediaFile && mediaFile.size > maxAppBannerImageBytes) {
        fs.unlinkSync(mediaFile.path);
        return res.status(400).json({
          error: "Banner image is too large. Keep it at or below 1 MB.",
        });
      }

      if (brochureFile && brochureFile.size > maxAppBannerPdfBytes) {
        fs.unlinkSync(brochureFile.path);
        return res.status(400).json({
          error: "Brochure PDF is too large. Keep it at or below 2 MB.",
        });
      }

      const banner = await prisma.appBanner.create({
        data: {
          associationId,
          vendorId,
          shortText: parsed.data.shortText,
          contactNumber: parsed.data.contactNumber,
          mediaUrl: mediaFile
            ? buildPublicAssetUrl(req, `uploads/app-banners/${mediaFile.filename}`)
            : null,
          mediaType: mediaFile?.mimetype || null,
          brochureUrl: brochureFile
            ? buildPublicAssetUrl(req, `uploads/app-banners/${brochureFile.filename}`)
            : null,
          brochureMimeType: brochureFile?.mimetype || null,
          socialMediaUrl: parsed.data.socialMediaUrl,
          reviewStatus: parsed.data.reviewStatus ?? PostReviewStatus.PENDING,
        },
        include: {
          vendor: true,
        },
      });

      return res.status(201).json({ banner: serializeAppBanner(req, banner) });
    } catch (error) {
      return res.status(400).json({
        error: error instanceof Error ? error.message : "Unable to save app banner",
      });
    }
  },
);

router.patch(
  "/:id",
  appBannerUpload.fields([
    { name: "mediaFile", maxCount: 1 },
    { name: "brochureFile", maxCount: 1 },
  ]),
  async (req, res) => {
    const parsed = appBannerUpdateSchema.safeParse(req.body);

    if (!parsed.success) {
      return res.status(400).json({
        error: "Invalid app banner payload",
        details: parsed.error.flatten(),
      });
    }

    try {
      const existingBanner = await prisma.appBanner.findUnique({
        where: { id: req.params.id },
      });

      if (!existingBanner) {
        return res.status(404).json({ error: "App banner not found" });
      }

      let vendorId = parsed.data.vendorId || null;
      let associationId =
        (await ensureAssociation(parsed.data.associationId)) ||
        existingBanner.associationId;

      if (vendorId) {
        const vendor = await prisma.vendor.findUnique({
          where: { id: vendorId },
        });

        if (!vendor) {
          return res.status(400).json({ error: "Selected vendor was not found." });
        }

        associationId = vendor.associationId;
      }

      const files = req.files || {};
      const mediaFile = Array.isArray(files.mediaFile) ? files.mediaFile[0] : null;
      const brochureFile = Array.isArray(files.brochureFile) ? files.brochureFile[0] : null;

      if (mediaFile && mediaFile.size > maxAppBannerImageBytes) {
        fs.unlinkSync(mediaFile.path);
        return res.status(400).json({
          error: "Banner image is too large. Keep it at or below 1 MB.",
        });
      }

      if (brochureFile && brochureFile.size > maxAppBannerPdfBytes) {
        fs.unlinkSync(brochureFile.path);
        return res.status(400).json({
          error: "Brochure PDF is too large. Keep it at or below 2 MB.",
        });
      }

      const banner = await prisma.appBanner.update({
        where: { id: existingBanner.id },
        data: {
          associationId,
          vendorId,
          shortText: parsed.data.shortText,
          contactNumber: parsed.data.contactNumber,
          socialMediaUrl: parsed.data.socialMediaUrl,
          mediaUrl: mediaFile
            ? buildPublicAssetUrl(req, `uploads/app-banners/${mediaFile.filename}`)
            : existingBanner.mediaUrl,
          mediaType: mediaFile?.mimetype || existingBanner.mediaType,
          brochureUrl: brochureFile
            ? buildPublicAssetUrl(req, `uploads/app-banners/${brochureFile.filename}`)
            : existingBanner.brochureUrl,
          brochureMimeType:
            brochureFile?.mimetype || existingBanner.brochureMimeType,
        },
        include: {
          vendor: true,
        },
      });

      if (mediaFile && existingBanner.mediaUrl !== banner.mediaUrl) {
        removeStoredAppBannerAsset(existingBanner.mediaUrl);
      }

      if (brochureFile && existingBanner.brochureUrl !== banner.brochureUrl) {
        removeStoredAppBannerAsset(existingBanner.brochureUrl);
      }

      return res.json({ banner: serializeAppBanner(req, banner) });
    } catch (error) {
      return res.status(400).json({
        error: error instanceof Error ? error.message : "Unable to update app banner",
      });
    }
  },
);

router.patch("/:id/moderation", async (req, res) => {
  const parsed = moderationSchema.safeParse(req.body);

  if (!parsed.success) {
    return res.status(400).json({
      error: "Invalid app banner moderation payload",
      details: parsed.error.flatten(),
    });
  }

  try {
    const banner = await applyAppBannerModeration(req.params.id, parsed.data);
    if (!banner) {
      return res.status(404).json({ error: "App banner not found" });
    }

    return res.json({ banner: serializeAppBanner(req, banner) });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unable to update app banner";
    const statusCode = message.includes("not found") ? 404 : 400;
    return res.status(statusCode).json({ error: message });
  }
});

router.delete("/:id", async (req, res) => {
  const banner = await prisma.appBanner.findUnique({
    where: { id: req.params.id },
  });

  if (!banner) {
    return res.status(404).json({ error: "App banner not found" });
  }

  await prisma.appBanner.delete({
    where: { id: banner.id },
  });

  removeStoredAppBannerAsset(banner.mediaUrl);
  removeStoredAppBannerAsset(banner.brochureUrl);

  return res.json({ success: true });
});

export default router;
