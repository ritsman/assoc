import { Router } from "express";
import prismaPkg from "@prisma/client";
import { z } from "zod";
import { prisma } from "../lib/prisma.js";
import {
  ensureAssociationId,
  normalizeTaxonomyName,
} from "../lib/vendor-taxonomy.js";

const router = Router();
const { Prisma } = prismaPkg;

const categorySchema = z.object({
  associationId: z.string().min(1).optional(),
  name: z.string().min(1),
});

const subCategorySchema = z.object({
  associationId: z.string().min(1).optional(),
  categoryId: z.string().min(1),
  name: z.string().min(1),
});

const subCategoryUpdateSchema = z.object({
  categoryId: z.string().min(1).optional(),
  name: z.string().min(1),
});

function isUniqueError(error) {
  return (
    error instanceof Prisma.PrismaClientKnownRequestError &&
    error.code === "P2002"
  );
}

function serializeCategory(category) {
  return {
    id: category.id,
    associationId: category.associationId,
    name: category.name,
    displayOrder: category.displayOrder,
    subCategories: (category.subCategories ?? []).map((subCategory) => ({
      id: subCategory.id,
      associationId: subCategory.associationId,
      categoryId: subCategory.categoryId,
      name: subCategory.name,
      displayOrder: subCategory.displayOrder,
    })),
  };
}

async function loadCategories(associationId) {
  return prisma.vendorCategory.findMany({
    where: { associationId },
    include: {
      subCategories: {
        orderBy: [{ displayOrder: "asc" }, { createdAt: "asc" }],
      },
    },
    orderBy: [{ displayOrder: "asc" }, { createdAt: "asc" }],
  });
}

router.get("/categories", async (req, res) => {
  const associationId = await ensureAssociationId(
    typeof req.query.associationId === "string" ? req.query.associationId : "",
  );
  const categories = await loadCategories(associationId);
  return res.json({ categories: categories.map(serializeCategory) });
});

router.post("/categories", async (req, res) => {
  const parsed = categorySchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({
      error: "Invalid vendor category payload",
      details: parsed.error.flatten(),
    });
  }

  const associationId = await ensureAssociationId(parsed.data.associationId);
  const name = normalizeTaxonomyName(parsed.data.name);
  if (!name) {
    return res.status(400).json({ error: "Category name is required" });
  }

  try {
    const count = await prisma.vendorCategory.count({
      where: { associationId },
    });
    const category = await prisma.vendorCategory.create({
      data: {
        associationId,
        name,
        displayOrder: count,
      },
      include: {
        subCategories: true,
      },
    });
    return res.status(201).json({ category: serializeCategory(category) });
  } catch (error) {
    if (isUniqueError(error)) {
      return res.status(409).json({ error: "Vendor category already exists" });
    }
    throw error;
  }
});

router.patch("/categories/:id", async (req, res) => {
  const parsed = categorySchema
    .omit({ associationId: true })
    .safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({
      error: "Invalid vendor category payload",
      details: parsed.error.flatten(),
    });
  }

  const existingCategory = await prisma.vendorCategory.findUnique({
    where: { id: req.params.id },
    include: { subCategories: true },
  });

  if (!existingCategory) {
    return res.status(404).json({ error: "Vendor category not found" });
  }

  const nextName = normalizeTaxonomyName(parsed.data.name);
  if (!nextName) {
    return res.status(400).json({ error: "Category name is required" });
  }

  try {
    const category = await prisma.$transaction(async (tx) => {
      const updatedCategory = await tx.vendorCategory.update({
        where: { id: existingCategory.id },
        data: { name: nextName },
        include: { subCategories: true },
      });

      if (existingCategory.name !== nextName) {
        await tx.vendor.updateMany({
          where: {
            associationId: existingCategory.associationId,
            category: existingCategory.name,
          },
          data: {
            category: nextName,
          },
        });
      }

      return updatedCategory;
    });

    return res.json({ category: serializeCategory(category) });
  } catch (error) {
    if (isUniqueError(error)) {
      return res.status(409).json({ error: "Vendor category already exists" });
    }
    throw error;
  }
});

router.delete("/categories/:id", async (req, res) => {
  const existingCategory = await prisma.vendorCategory.findUnique({
    where: { id: req.params.id },
  });

  if (!existingCategory) {
    return res.status(404).json({ error: "Vendor category not found" });
  }

  await prisma.$transaction(async (tx) => {
    await tx.vendor.updateMany({
      where: {
        associationId: existingCategory.associationId,
        category: existingCategory.name,
      },
      data: {
        category: null,
        vendorType: null,
      },
    });

    await tx.vendorCategory.delete({
      where: { id: existingCategory.id },
    });
  });

  return res.status(204).send();
});

router.get("/sub-categories", async (req, res) => {
  const categoryId =
    typeof req.query.categoryId === "string" ? req.query.categoryId : "";

  if (!categoryId) {
    return res.status(400).json({ error: "categoryId is required" });
  }

  const subCategories = await prisma.vendorSubCategory.findMany({
    where: { categoryId },
    orderBy: [{ displayOrder: "asc" }, { createdAt: "asc" }],
  });

  return res.json({ subCategories });
});

router.post("/sub-categories", async (req, res) => {
  const parsed = subCategorySchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({
      error: "Invalid vendor sub category payload",
      details: parsed.error.flatten(),
    });
  }

  const parentCategory = await prisma.vendorCategory.findUnique({
    where: { id: parsed.data.categoryId },
  });

  if (!parentCategory) {
    return res.status(404).json({ error: "Parent category not found" });
  }

  const associationId = await ensureAssociationId(
    parsed.data.associationId || parentCategory.associationId,
  );
  const name = normalizeTaxonomyName(parsed.data.name);
  if (!name) {
    return res.status(400).json({ error: "Sub category name is required" });
  }

  try {
    const count = await prisma.vendorSubCategory.count({
      where: { categoryId: parentCategory.id },
    });
    const subCategory = await prisma.vendorSubCategory.create({
      data: {
        associationId,
        categoryId: parentCategory.id,
        name,
        displayOrder: count,
      },
    });
    return res.status(201).json({ subCategory });
  } catch (error) {
    if (isUniqueError(error)) {
      return res
        .status(409)
        .json({ error: "Vendor sub category already exists" });
    }
    throw error;
  }
});

router.patch("/sub-categories/:id", async (req, res) => {
  const parsed = subCategoryUpdateSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({
      error: "Invalid vendor sub category payload",
      details: parsed.error.flatten(),
    });
  }

  const existingSubCategory = await prisma.vendorSubCategory.findUnique({
    where: { id: req.params.id },
    include: { category: true },
  });

  if (!existingSubCategory) {
    return res.status(404).json({ error: "Vendor sub category not found" });
  }

  const nextName = normalizeTaxonomyName(parsed.data.name);
  if (!nextName) {
    return res.status(400).json({ error: "Sub category name is required" });
  }

  const nextCategoryId =
    parsed.data.categoryId || existingSubCategory.categoryId;
  const nextCategory = await prisma.vendorCategory.findUnique({
    where: { id: nextCategoryId },
  });

  if (!nextCategory) {
    return res.status(404).json({ error: "Parent category not found" });
  }

  try {
    const subCategory = await prisma.$transaction(async (tx) => {
      const updatedSubCategory = await tx.vendorSubCategory.update({
        where: { id: existingSubCategory.id },
        data: {
          categoryId: nextCategory.id,
          associationId: nextCategory.associationId,
          name: nextName,
        },
      });

      await tx.vendor.updateMany({
        where: {
          associationId: existingSubCategory.associationId,
          category: existingSubCategory.category.name,
          vendorType: existingSubCategory.name,
        },
        data: {
          category: nextCategory.name,
          vendorType: nextName,
        },
      });

      return updatedSubCategory;
    });

    return res.json({ subCategory });
  } catch (error) {
    if (isUniqueError(error)) {
      return res
        .status(409)
        .json({ error: "Vendor sub category already exists" });
    }
    throw error;
  }
});

router.delete("/sub-categories/:id", async (req, res) => {
  const existingSubCategory = await prisma.vendorSubCategory.findUnique({
    where: { id: req.params.id },
    include: { category: true },
  });

  if (!existingSubCategory) {
    return res.status(404).json({ error: "Vendor sub category not found" });
  }

  await prisma.$transaction(async (tx) => {
    await tx.vendor.updateMany({
      where: {
        associationId: existingSubCategory.associationId,
        category: existingSubCategory.category.name,
        vendorType: existingSubCategory.name,
      },
      data: {
        vendorType: null,
      },
    });

    await tx.vendorSubCategory.delete({
      where: { id: existingSubCategory.id },
    });
  });

  return res.status(204).send();
});

export default router;
