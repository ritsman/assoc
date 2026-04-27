import { Router } from "express";
import prismaPkg from "@prisma/client";
import { z } from "zod";
import { prisma } from "../lib/prisma.js";

const router = Router();
const { MemberStatus, PaymentStatus } = prismaPkg;

const memberSchema = z.object({
  associationId: z.string().min(1).optional(),
  firstName: z.string().min(1),
  lastName: z.string().min(1),
  email: z.string().email(),
  phone: z.string().optional(),
  address: z.string().optional(),
  gst: z.string().optional(),
  companyName: z.string().optional(),
  roleTitle: z.string().optional(),
  specialization: z.string().optional(),
  membershipDetails: z.string().optional(),
  membershipStartDate: z.coerce.date().optional(),
  membershipEndDate: z.coerce.date().optional(),
  paymentAmount: z.string().optional(),
  paymentStatus: z.nativeEnum(PaymentStatus).optional(),
  customFieldValues: z.record(z.string(), z.string()).optional(),
  membershipStatus: z.nativeEnum(MemberStatus).optional(),
});

const memberUpdateSchema = memberSchema.partial();

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

  const member = await prisma.member.create({
    data: {
      ...parsed.data,
      associationId,
    },
    include: {
      association: true,
    },
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

  const member = await prisma.member.update({
    where: { id: req.params.id },
    data: {
      ...parsed.data,
      ...(associationId ? { associationId } : {}),
    },
    include: {
      association: true,
    },
  });

  return res.json({ member });
});

router.delete("/:id", async (req, res) => {
  await prisma.member.delete({
    where: { id: req.params.id },
  });

  return res.status(204).send();
});

export default router;
