import { prisma } from "./prisma.js";

function normalizeTaxonomyName(value) {
  const nextValue = String(value || "").trim();
  return nextValue || null;
}

async function ensureAssociationId(associationId, tx = prisma) {
  if (associationId) {
    return associationId;
  }

  const existingAssociation = await tx.association.findFirst({
    orderBy: { createdAt: "asc" },
  });

  if (existingAssociation) {
    return existingAssociation.id;
  }

  const defaultAssociation = await tx.association.create({
    data: {
      name: "Association 1",
      slug: "association-1",
      appName: "Synetra",
      isActive: true,
    },
  });

  return defaultAssociation.id;
}

async function ensureCategory(tx, associationId, name) {
  const normalizedName = normalizeTaxonomyName(name);
  if (!normalizedName) {
    return null;
  }

  const exactMatch = await tx.vendorCategory.findFirst({
    where: {
      associationId,
      name: normalizedName,
    },
  });

  if (exactMatch) {
    return exactMatch;
  }

  const existing = await tx.vendorCategory.findFirst({
    where: {
      associationId,
      name: {
        equals: normalizedName,
        mode: "insensitive",
      },
    },
  });

  if (existing) {
    // Reuse the existing category instead of renaming it during backfills,
    // which can collide with another row that already has the normalized name.
    return existing;
  }

  const count = await tx.vendorCategory.count({
    where: { associationId },
  });

  return tx.vendorCategory.create({
    data: {
      associationId,
      name: normalizedName,
      displayOrder: count,
    },
  });
}

async function ensureSubCategory(tx, associationId, categoryId, name) {
  const normalizedName = normalizeTaxonomyName(name);
  if (!normalizedName || !categoryId) {
    return null;
  }

  const exactMatch = await tx.vendorSubCategory.findFirst({
    where: {
      categoryId,
      name: normalizedName,
    },
  });

  if (exactMatch) {
    return exactMatch;
  }

  const existing = await tx.vendorSubCategory.findFirst({
    where: {
      categoryId,
      name: {
        equals: normalizedName,
        mode: "insensitive",
      },
    },
  });

  if (existing) {
    return existing;
  }

  const count = await tx.vendorSubCategory.count({
    where: { categoryId },
  });

  return tx.vendorSubCategory.create({
    data: {
      associationId,
      categoryId,
      name: normalizedName,
      displayOrder: count,
    },
  });
}

export async function syncVendorTaxonomyFromVendorInput(
  tx,
  associationId,
  categoryName,
  subCategoryName,
) {
  const resolvedAssociationId = await ensureAssociationId(associationId, tx);
  const category = await ensureCategory(
    tx,
    resolvedAssociationId,
    categoryName,
  );

  if (!category) {
    return { category: null, subCategory: null };
  }

  const subCategory = await ensureSubCategory(
    tx,
    resolvedAssociationId,
    category.id,
    subCategoryName,
  );

  return { category, subCategory };
}

export async function backfillVendorTaxonomy() {
  const vendors = await prisma.vendor.findMany({
    select: {
      associationId: true,
      category: true,
      vendorType: true,
    },
    orderBy: { createdAt: "asc" },
  });

  await prisma.$transaction(async (tx) => {
    for (const vendor of vendors) {
      await syncVendorTaxonomyFromVendorInput(
        tx,
        vendor.associationId,
        vendor.category,
        vendor.vendorType,
      );
    }
  });
}

export { ensureAssociationId, normalizeTaxonomyName };
