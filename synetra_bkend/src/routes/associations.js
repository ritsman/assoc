import { Router } from "express";
import { z } from "zod";
import { prisma } from "../lib/prisma.js";

const router = Router();

const associationSchema = z.object({
  name: z.string().min(2),
  slug: z.string().min(2),
  sector: z.string().optional(),
  description: z.string().optional(),
  logoUrl: z.string().url().optional(),
  primaryColor: z.string().optional(),
  appName: z.string().optional(),
  domain: z.string().optional(),
  isActive: z.boolean().optional(),
});

router.get("/", async (_req, res) => {
  const associations = await prisma.association.findMany({
    include: {
      _count: {
        select: { members: true },
      },
    },
    orderBy: { createdAt: "desc" },
  });

  res.json({ associations });
});

router.post("/", async (req, res) => {
  const parsed = associationSchema.safeParse(req.body);

  if (!parsed.success) {
    return res.status(400).json({
      error: "Invalid association payload",
      details: parsed.error.flatten(),
    });
  }

  const association = await prisma.association.create({
    data: parsed.data,
  });

  return res.status(201).json({ association });
});

export default router;
