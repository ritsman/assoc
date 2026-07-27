import prismaPkg from "@prisma/client";
import { hashPassword } from "./auth.js";
import { prisma } from "./prisma.js";

const { ApprovalStatus } = prismaPkg;

const BOOTSTRAP_ADMIN_EMAIL = (
  process.env.BOOTSTRAP_ADMIN_EMAIL || "ritsman@gmail.com"
)
  .trim()
  .toLowerCase();
const BOOTSTRAP_ADMIN_PASSWORD =
  process.env.BOOTSTRAP_ADMIN_PASSWORD || "Admin@123";
const BOOTSTRAP_ADMIN_FIRST_NAME =
  process.env.BOOTSTRAP_ADMIN_FIRST_NAME || "Ritsman";
const BOOTSTRAP_ADMIN_LAST_NAME =
  process.env.BOOTSTRAP_ADMIN_LAST_NAME || "Admin";

export async function ensureBootstrapAdmin() {
  if (!BOOTSTRAP_ADMIN_EMAIL || !BOOTSTRAP_ADMIN_PASSWORD) {
    return;
  }

  const passwordHash = await hashPassword(BOOTSTRAP_ADMIN_PASSWORD);
  const existingUser = await prisma.user.findUnique({
    where: {
      email: BOOTSTRAP_ADMIN_EMAIL,
    },
  });

  if (existingUser) {
    await prisma.user.update({
      where: { id: existingUser.id },
      data: {
        firstName: existingUser.firstName || BOOTSTRAP_ADMIN_FIRST_NAME,
        lastName: existingUser.lastName || BOOTSTRAP_ADMIN_LAST_NAME,
        passwordHash,
        isAdmin: true,
        isSuperAdmin: true,
        isActive: true,
        approvalStatus: ApprovalStatus.APPROVED,
        approvedAt: existingUser.approvedAt ?? new Date(),
        rejectedAt: null,
      },
    });
    return;
  }

  const primaryAssociation = await prisma.association.findFirst({
    orderBy: { createdAt: "asc" },
    select: { id: true },
  });

  await prisma.user.create({
    data: {
      associationId: primaryAssociation?.id,
      firstName: BOOTSTRAP_ADMIN_FIRST_NAME,
      lastName: BOOTSTRAP_ADMIN_LAST_NAME,
      email: BOOTSTRAP_ADMIN_EMAIL,
      passwordHash,
      isAdmin: true,
      isSuperAdmin: true,
      isActive: true,
      approvalStatus: ApprovalStatus.APPROVED,
      approvedAt: new Date(),
    },
  });
}
