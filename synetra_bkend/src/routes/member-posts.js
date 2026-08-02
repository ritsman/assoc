import fs from "fs";
import path from "path";
import multer from "multer";
import { Router } from "express";
import { fileURLToPath } from "url";
import { z } from "zod";
import {
  buildPublicAssetUrl,
  buildPublicThumbnailUrl,
  resolvePublicAssetUrl,
} from "../lib/public-url.js";
import {
  isInlineDataImageUrl,
  persistInlineImageDataUrl,
} from "../lib/inline-image-assets.js";
import { prisma } from "../lib/prisma.js";
import { getUploadSubdirPath } from "../lib/uploads-dir.js";

const router = Router();
const postReviewStatuses = ["PENDING", "APPROVED", "REJECTED"];
const currentFilePath = fileURLToPath(import.meta.url);
const memberPostUploadsDirPath = getUploadSubdirPath("member-posts");
const memberPhotoUploadsDirPath = getUploadSubdirPath("member-photos");

const optionalDateField = z.preprocess(
  (value) => (value === "" || value === null ? undefined : value),
  z.coerce.date().optional(),
);

const memberPostSchema = z.object({
  memberId: z.string().min(1),
  title: z.string().min(1),
  summary: z.string().min(1),
  body: z.string().optional(),
  mediaUrl: z.string().optional(),
  mediaType: z.string().optional(),
  postType: z.string().optional(),
  displayStart: optionalDateField,
  displayEnd: optionalDateField,
});

const memberPostStorage = multer.diskStorage({
  destination: (_req, _file, callback) => {
    fs.mkdirSync(memberPostUploadsDirPath, { recursive: true });
    callback(null, memberPostUploadsDirPath);
  },
  filename: (_req, file, callback) => {
    const safeBaseName = path
      .basename(file.originalname, path.extname(file.originalname))
      .replace(/[^a-zA-Z0-9-_]+/g, "-")
      .replace(/^-+|-+$/g, "")
      .slice(0, 60);
    callback(
      null,
      `${Date.now()}-${safeBaseName || "member-post"}${path.extname(file.originalname)}`,
    );
  },
});

const memberPostUpload = multer({
  storage: memberPostStorage,
  limits: {
    fileSize: 10 * 1024 * 1024,
  },
  fileFilter: (_req, file, callback) => {
    if (!file.mimetype.startsWith("image/")) {
      callback(new Error("Only image uploads are allowed for member posts."));
      return;
    }

    callback(null, true);
  },
});

const moderationSchema = z.object({
  reviewStatus: z.enum(postReviewStatuses),
  displayStart: optionalDateField,
  displayEnd: optionalDateField,
});

async function normalizeNestedMemberPhoto(member) {
  if (!member?.id || !isInlineDataImageUrl(member.photoUrl)) {
    return member;
  }

  const nextPhotoUrl = persistInlineImageDataUrl({
    dataUrl: member.photoUrl,
    uploadsDirPath: memberPhotoUploadsDirPath,
    publicPathPrefix: "uploads/member-photos",
    fallbackBaseName: member.id,
  });

  if (nextPhotoUrl === member.photoUrl) {
    return member;
  }

  return prisma.member.update({
    where: { id: member.id },
    data: { photoUrl: nextPhotoUrl },
  });
}

async function normalizeMemberPostRecord(post) {
  if (!post?.member) {
    return post;
  }

  return {
    ...post,
    member: await normalizeNestedMemberPhoto(post.member),
  };
}

function serializeMemberPost(req, post) {
  const memberName =
    `${post.member.firstName ?? ""} ${post.member.lastName ?? ""}`.trim();
  return {
    id: post.id,
    memberId: post.memberId,
    title: post.title,
    summary: post.summary,
    body: post.body,
    mediaUrl: resolvePublicAssetUrl(req, post.mediaUrl),
    thumbnailUrl: buildPublicThumbnailUrl(req, post.mediaUrl),
    mediaType: post.mediaType,
    postType: post.postType || "Post",
    reviewStatus: post.reviewStatus,
    displayStart: post.displayStart?.toISOString().slice(0, 10) ?? "",
    displayEnd: post.displayEnd?.toISOString().slice(0, 10) ?? "",
    postedOn: post.createdAt.toISOString().slice(0, 10),
    createdAt: post.createdAt,
    updatedAt: post.updatedAt,
    member: {
      id: post.member.id,
      name: memberName,
      company: post.member.companyName || "",
      photoUrl: resolvePublicAssetUrl(req, post.member.photoUrl),
      thumbnailUrl: buildPublicThumbnailUrl(req, post.member.photoUrl),
    },
  };
}

router.get("/", async (req, res) => {
  const { associationId, memberId, reviewStatus } = req.query;
  const statusFilter =
    typeof reviewStatus === "string" &&
    postReviewStatuses.includes(reviewStatus)
      ? reviewStatus
      : undefined;

  const posts = await prisma.memberPost.findMany({
    where: {
      ...(associationId ? { associationId: String(associationId) } : {}),
      ...(memberId ? { memberId: String(memberId) } : {}),
      ...(statusFilter ? { reviewStatus: statusFilter } : {}),
    },
    include: {
      member: true,
    },
    orderBy: { createdAt: "desc" },
  });

  const normalizedPosts = await Promise.all(posts.map(normalizeMemberPostRecord));

  return res.json({
    posts: normalizedPosts.map((post) => serializeMemberPost(req, post)),
  });
});

router.post("/", memberPostUpload.single("imageFile"), async (req, res) => {
  const parsed = memberPostSchema.safeParse(req.body);

  if (!parsed.success) {
    return res.status(400).json({
      error: "Invalid member post payload",
      details: parsed.error.flatten(),
    });
  }

  const member = await prisma.member.findUnique({
    where: { id: parsed.data.memberId },
  });

  if (!member) {
    return res.status(404).json({ error: "Member not found" });
  }

  const post = await prisma.memberPost.create({
    data: {
      memberId: member.id,
      associationId: member.associationId,
      title: parsed.data.title,
      summary: parsed.data.summary,
      body: parsed.data.body,
      mediaUrl: req.file
        ? buildPublicAssetUrl(req, `uploads/member-posts/${req.file.filename}`)
        : parsed.data.mediaUrl,
      mediaType: req.file ? req.file.mimetype : parsed.data.mediaType,
      postType: parsed.data.postType,
      displayStart: parsed.data.displayStart,
      displayEnd: parsed.data.displayEnd,
    },
    include: {
      member: true,
    },
  });

  return res.status(201).json({
    post: serializeMemberPost(req, await normalizeMemberPostRecord(post)),
  });
});

router.patch("/:id/moderation", async (req, res) => {
  const parsed = moderationSchema.safeParse(req.body);

  if (!parsed.success) {
    return res.status(400).json({
      error: "Invalid post moderation payload",
      details: parsed.error.flatten(),
    });
  }

  const existingPost = await prisma.memberPost.findUnique({
    where: { id: req.params.id },
  });

  if (!existingPost) {
    return res.status(404).json({ error: "Post not found" });
  }

  const nextReviewStatus = parsed.data.reviewStatus;
  const post = await prisma.memberPost.update({
    where: { id: req.params.id },
    data: {
      reviewStatus: nextReviewStatus,
      displayStart: parsed.data.displayStart,
      displayEnd: parsed.data.displayEnd,
      approvedAt: nextReviewStatus === "APPROVED" ? new Date() : null,
      rejectedAt: nextReviewStatus === "REJECTED" ? new Date() : null,
    },
    include: {
      member: true,
    },
  });

  return res.json({
    post: serializeMemberPost(req, await normalizeMemberPostRecord(post)),
  });
});

export default router;
