import { prisma } from "./prisma.js";

export async function ensureAssociationAppAccess(associationId) {
  const existingAppAccess = await prisma.associationAppAccess.findUnique({
    where: { associationId },
  });

  if (existingAppAccess) {
    return existingAppAccess;
  }

  return prisma.associationAppAccess.create({
    data: {
      associationId,
    },
  });
}

export async function getAssociationAppAccess(associationId) {
  if (!associationId) {
    return null;
  }

  return ensureAssociationAppAccess(associationId);
}
