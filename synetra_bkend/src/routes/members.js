import { Router } from "express";
import { MemberStatus } from "@prisma/client";
import { z } from "zod";
import { prisma } from "../lib/prisma.js";

const router = Router();

const memberSchema = z.object({
  associationId: z.string().min(1),
  firstName: z.string().min(1),
  lastName: z.string().min(1),
  email: z.string().email(),
  phone: z.string().optional(),
  companyName: z.string().optional(),
  roleTitle: z.string().optional(),
  specialization: z.string().optional(),
  membershipStatus: z.nativeEnum(MemberStatus).optional(),
});

router.get("/", async (req, res) => {
  const { associationId } = req.query;

  const members = await prisma.member.findMany({
    where: {
      ...(associationId ? { associationId: String(associationId) } : {}),
    },
    include: {
      association: true,
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

  const member = await prisma.member.create({
    data: parsed.data,
    include: {
      association: true,
    },
  });

  return res.status(201).json({ member });
});

export default router;
