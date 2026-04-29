import { Router } from "express";
import prismaPkg from "@prisma/client";
import { z } from "zod";
import { prisma } from "../lib/prisma.js";

const router = Router();
const { PostReviewStatus } = prismaPkg;

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

const moderationSchema = z.object({
  reviewStatus: z.nativeEnum(PostReviewStatus),
  displayStart: optionalDateField,
  displayEnd: optionalDateField,
});

function serializeMemberPost(post) {
  const memberName = `${post.member.firstName ?? ""} ${post.member.lastName ?? ""}`.trim();
  return {
    id: post.id,
    memberId: post.memberId,
    title: post.title,
    summary: post.summary,
    body: post.body,
    mediaUrl: post.mediaUrl,
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
      photoUrl: post.member.photoUrl || "",
    },
  };
}

router.get("/", async (req, res) => {
  const { associationId, memberId } = req.query;

  const posts = await prisma.memberPost.findMany({
    where: {
      ...(associationId ? { associationId: String(associationId) } : {}),
      ...(memberId ? { memberId: String(memberId) } : {}),
    },
    include: {
      member: true,
    },
    orderBy: { createdAt: "desc" },
  });

  return res.json({ posts: posts.map(serializeMemberPost) });
});

router.post("/", async (req, res) => {
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
      mediaUrl: parsed.data.mediaUrl,
      mediaType: parsed.data.mediaType,
      postType: parsed.data.postType,
      displayStart: parsed.data.displayStart,
      displayEnd: parsed.data.displayEnd,
    },
    include: {
      member: true,
    },
  });

  return res.status(201).json({ post: serializeMemberPost(post) });
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
      approvedAt: nextReviewStatus === PostReviewStatus.APPROVED ? new Date() : null,
      rejectedAt: nextReviewStatus === PostReviewStatus.REJECTED ? new Date() : null,
    },
    include: {
      member: true,
    },
  });

  return res.json({ post: serializeMemberPost(post) });
});

export default router;
