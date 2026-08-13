import fs from "fs";
import path from "path";
import multer from "multer";
import { Router } from "express";
import prismaPkg from "@prisma/client";
import { fileURLToPath } from "url";
import { z } from "zod";
import {
  buildPublicAssetUrl,
  buildPublicThumbnailUrl,
  resolvePublicAssetUrl,
} from "../lib/public-url.js";
import { prisma } from "../lib/prisma.js";
import { getUploadSubdirPath } from "../lib/uploads-dir.js";

const router = Router();
const { PostReviewStatus, TimelineSourceType } = prismaPkg;
const currentFilePath = fileURLToPath(import.meta.url);
const timelineUploadsDirPath = getUploadSubdirPath("timeline-posts");

const optionalDateField = z.preprocess(
  (value) => (value === "" || value === null ? undefined : value),
  z.coerce.date().optional(),
);

const timelinePostSchema = z.object({
  associationId: z.string().min(1).optional(),
  sourceType: z.nativeEnum(TimelineSourceType),
  memberId: z.string().optional(),
  vendorId: z.string().optional(),
  postedBy: z.string().optional(),
  caption: z.string().min(1),
  contactNumber: z.string().optional(),
  landingPageUrl: z.string().optional(),
  youtubeUrl: z.string().optional(),
  facebookUrl: z.string().optional(),
  brochureUrl: z.string().optional(),
  reviewStatus: z.nativeEnum(PostReviewStatus).optional(),
  displayStart: optionalDateField,
  displayEnd: optionalDateField,
});

const timelinePostUpdateSchema = z.object({
  associationId: z.string().min(1).optional(),
  sourceType: z.nativeEnum(TimelineSourceType),
  memberId: z.string().optional(),
  vendorId: z.string().optional(),
  postedBy: z.string().optional(),
  caption: z.string().min(1),
  contactNumber: z.string().optional(),
  landingPageUrl: z.string().optional(),
  youtubeUrl: z.string().optional(),
  facebookUrl: z.string().optional(),
  brochureUrl: z.string().optional(),
});

const moderationSchema = z.object({
  reviewStatus: z.nativeEnum(PostReviewStatus),
  displayStart: optionalDateField,
  displayEnd: optionalDateField,
});

const timelinePostStorage = multer.diskStorage({
  destination: (_req, _file, callback) => {
    fs.mkdirSync(timelineUploadsDirPath, { recursive: true });
    callback(null, timelineUploadsDirPath);
  },
  filename: (_req, file, callback) => {
    const safeBaseName = path
      .basename(file.originalname, path.extname(file.originalname))
      .replace(/[^a-zA-Z0-9-_]+/g, "-")
      .replace(/^-+|-+$/g, "")
      .slice(0, 60);
    callback(
      null,
      `${Date.now()}-${safeBaseName || "timeline-asset"}${path.extname(file.originalname)}`,
    );
  },
});

const timelinePostUpload = multer({
  storage: timelinePostStorage,
  limits: {
    fileSize: 15 * 1024 * 1024,
  },
  fileFilter: (_req, file, callback) => {
    const isImage = file.mimetype.startsWith("image/");
    const isPdf = file.mimetype === "application/pdf";

    if (!isImage && !isPdf) {
      callback(new Error("Timeline uploads only support images and PDF brochures."));
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

function resolveTimelineSourceName(post) {
  if (post.sourceType === "MEMBER") {
    return `${post.member?.firstName ?? ""} ${post.member?.lastName ?? ""}`.trim() || "Member";
  }

  if (post.sourceType === "VENDOR") {
    return post.vendor?.companyName || post.vendor?.name || "Vendor";
  }

  return post.association?.name || "Association";
}

function resolveTimelineSourceId(post) {
  if (post.sourceType === "MEMBER") {
    return post.memberId || "";
  }

  if (post.sourceType === "VENDOR") {
    return post.vendorId || "";
  }

  return post.associationId || "";
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

function removeStoredTimelineAsset(assetUrl) {
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

  if (!normalizedPath.startsWith("uploads/timeline-posts/")) {
    return;
  }

  const absolutePath = path.join(path.dirname(currentFilePath), "../../", normalizedPath);

  if (fs.existsSync(absolutePath)) {
    fs.unlinkSync(absolutePath);
  }
}

function serializeTimelinePost(req, post) {
  return {
    id: post.id,
    associationId: post.associationId,
    sourceType: post.sourceType,
    sourceId: resolveTimelineSourceId(post),
    sourceName: resolveTimelineSourceName(post),
    postedBy: post.postedBy || "",
    caption: post.caption,
    contactNumber: post.contactNumber || "",
    imageUrl: resolvePublicAssetUrl(req, post.imageUrl),
    imageThumbnailUrl: buildPublicThumbnailUrl(req, post.imageUrl),
    imageType: post.imageType || "",
    landingPageUrl: post.landingPageUrl || "",
    youtubeUrl: post.youtubeUrl || "",
    facebookUrl: post.facebookUrl || "",
    brochureUrl: resolvePublicAssetUrl(req, post.brochureUrl),
    brochureMimeType: post.brochureMimeType || "",
    reviewStatus: post.reviewStatus,
    displayStart: post.displayStart?.toISOString().slice(0, 10) ?? "",
    displayEnd: post.displayEnd?.toISOString().slice(0, 10) ?? "",
    postedOn: post.createdAt.toISOString().slice(0, 10),
    createdAt: post.createdAt,
    updatedAt: post.updatedAt,
  };
}

async function resolveSourceContext(parsedData) {
  if (parsedData.sourceType === "MEMBER") {
    if (!parsedData.memberId) {
      throw new Error("A member must be selected for member timeline posts.");
    }

    const member = await prisma.member.findUnique({
      where: { id: parsedData.memberId },
    });

    if (!member) {
      throw new Error("Selected member was not found.");
    }

    return {
      associationId: member.associationId,
      memberId: member.id,
      vendorId: null,
    };
  }

  if (parsedData.sourceType === "VENDOR") {
    if (!parsedData.vendorId) {
      throw new Error("A vendor must be selected for vendor timeline posts.");
    }

    const vendor = await prisma.vendor.findUnique({
      where: { id: parsedData.vendorId },
    });

    if (!vendor) {
      throw new Error("Selected vendor was not found.");
    }

    return {
      associationId: vendor.associationId,
      memberId: null,
      vendorId: vendor.id,
    };
  }

  return {
    associationId: await ensureAssociation(parsedData.associationId),
    memberId: null,
    vendorId: null,
  };
}

router.get("/", async (req, res) => {
  const { associationId, sourceType } = req.query;
  const sourceTypeFilter =
    typeof sourceType === "string" && Object.values(TimelineSourceType).includes(sourceType)
      ? sourceType
      : undefined;

  const posts = await prisma.timelinePost.findMany({
    where: {
      ...(associationId ? { associationId: String(associationId) } : {}),
      ...(sourceTypeFilter ? { sourceType: sourceTypeFilter } : {}),
    },
    include: {
      association: true,
      member: true,
      vendor: true,
    },
    orderBy: { createdAt: "desc" },
  });

  return res.json({ posts: posts.map((post) => serializeTimelinePost(req, post)) });
});

router.post(
  "/",
  timelinePostUpload.fields([
    { name: "imageFile", maxCount: 1 },
    { name: "brochureFile", maxCount: 1 },
  ]),
  async (req, res) => {
    const parsed = timelinePostSchema.safeParse(req.body);

    if (!parsed.success) {
      return res.status(400).json({
        error: "Invalid timeline post payload",
        details: parsed.error.flatten(),
      });
    }

    try {
      const sourceContext = await resolveSourceContext(parsed.data);
      const files = req.files || {};
      const imageFile = Array.isArray(files.imageFile) ? files.imageFile[0] : null;
      const brochureFile = Array.isArray(files.brochureFile) ? files.brochureFile[0] : null;
      const defaultDisplayWindow = buildDefaultDisplayWindow(
        parsed.data.displayStart,
        parsed.data.displayEnd,
      );

      const post = await prisma.timelinePost.create({
        data: {
          associationId: sourceContext.associationId,
          sourceType: parsed.data.sourceType,
          memberId: sourceContext.memberId,
          vendorId: sourceContext.vendorId,
          postedBy: parsed.data.postedBy,
          caption: parsed.data.caption,
          contactNumber: parsed.data.contactNumber,
          imageUrl: imageFile
            ? buildPublicAssetUrl(req, `uploads/timeline-posts/${imageFile.filename}`)
            : null,
          imageType: imageFile?.mimetype || null,
          landingPageUrl: parsed.data.landingPageUrl,
          youtubeUrl: parsed.data.youtubeUrl,
          facebookUrl: parsed.data.facebookUrl,
          brochureUrl: brochureFile
            ? buildPublicAssetUrl(req, `uploads/timeline-posts/${brochureFile.filename}`)
            : parsed.data.brochureUrl,
          brochureMimeType: brochureFile?.mimetype || null,
          reviewStatus: parsed.data.reviewStatus ?? PostReviewStatus.PENDING,
          displayStart: defaultDisplayWindow.displayStart,
          displayEnd: defaultDisplayWindow.displayEnd,
        },
        include: {
          association: true,
          member: true,
          vendor: true,
        },
      });

      return res.status(201).json({ post: serializeTimelinePost(req, post) });
    } catch (error) {
      return res.status(400).json({
        error: error instanceof Error ? error.message : "Unable to save timeline post",
      });
    }
  },
);

router.patch(
  "/:id",
  timelinePostUpload.fields([
    { name: "imageFile", maxCount: 1 },
    { name: "brochureFile", maxCount: 1 },
  ]),
  async (req, res) => {
    const parsed = timelinePostUpdateSchema.safeParse(req.body);

    if (!parsed.success) {
      return res.status(400).json({
        error: "Invalid timeline post payload",
        details: parsed.error.flatten(),
      });
    }

    try {
      const existingPost = await prisma.timelinePost.findUnique({
        where: { id: req.params.id },
      });

      if (!existingPost) {
        return res.status(404).json({ error: "Timeline post not found" });
      }

      const sourceContext = await resolveSourceContext(parsed.data);
      const files = req.files || {};
      const imageFile = Array.isArray(files.imageFile) ? files.imageFile[0] : null;
      const brochureFile = Array.isArray(files.brochureFile) ? files.brochureFile[0] : null;

      const post = await prisma.timelinePost.update({
        where: { id: existingPost.id },
        data: {
          associationId: sourceContext.associationId,
          sourceType: parsed.data.sourceType,
          memberId: sourceContext.memberId,
          vendorId: sourceContext.vendorId,
          postedBy: parsed.data.postedBy,
          caption: parsed.data.caption,
          contactNumber: parsed.data.contactNumber,
          imageUrl: imageFile
            ? buildPublicAssetUrl(req, `uploads/timeline-posts/${imageFile.filename}`)
            : existingPost.imageUrl,
          imageType: imageFile?.mimetype || existingPost.imageType,
          landingPageUrl: parsed.data.landingPageUrl,
          youtubeUrl: parsed.data.youtubeUrl,
          facebookUrl: parsed.data.facebookUrl,
          brochureUrl: brochureFile
            ? buildPublicAssetUrl(req, `uploads/timeline-posts/${brochureFile.filename}`)
            : parsed.data.brochureUrl || existingPost.brochureUrl,
          brochureMimeType: brochureFile?.mimetype || existingPost.brochureMimeType,
        },
        include: {
          association: true,
          member: true,
          vendor: true,
        },
      });

      if (imageFile && existingPost.imageUrl !== post.imageUrl) {
        removeStoredTimelineAsset(existingPost.imageUrl);
      }

      if (brochureFile && existingPost.brochureUrl !== post.brochureUrl) {
        removeStoredTimelineAsset(existingPost.brochureUrl);
      }

      return res.json({ post: serializeTimelinePost(req, post) });
    } catch (error) {
      return res.status(400).json({
        error: error instanceof Error ? error.message : "Unable to update timeline post",
      });
    }
  },
);

router.patch("/:id/moderation", async (req, res) => {
  const parsed = moderationSchema.safeParse(req.body);

  if (!parsed.success) {
    return res.status(400).json({
      error: "Invalid timeline moderation payload",
      details: parsed.error.flatten(),
    });
  }

  const existingPost = await prisma.timelinePost.findUnique({
    where: { id: req.params.id },
  });

  if (!existingPost) {
    return res.status(404).json({ error: "Timeline post not found" });
  }

  const post = await prisma.timelinePost.update({
    where: { id: req.params.id },
    data: {
      reviewStatus: parsed.data.reviewStatus,
      displayStart: parsed.data.displayStart,
      displayEnd: parsed.data.displayEnd,
    },
    include: {
      association: true,
      member: true,
      vendor: true,
    },
  });

  return res.json({ post: serializeTimelinePost(req, post) });
});

router.delete("/:id", async (req, res) => {
  const existingPost = await prisma.timelinePost.findUnique({
    where: { id: req.params.id },
  });

  if (!existingPost) {
    return res.status(404).json({ error: "Timeline post not found" });
  }

  await prisma.timelinePost.delete({
    where: { id: existingPost.id },
  });

  removeStoredTimelineAsset(existingPost.imageUrl);
  removeStoredTimelineAsset(existingPost.brochureUrl);

  return res.json({ success: true });
});

export default router;
