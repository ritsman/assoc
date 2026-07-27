ALTER TABLE "User"
ADD COLUMN "isSuperAdmin" BOOLEAN NOT NULL DEFAULT false;

CREATE INDEX "User_isAdmin_isSuperAdmin_isMember_isVendor_idx"
ON "User"("isAdmin", "isSuperAdmin", "isMember", "isVendor");

DROP INDEX IF EXISTS "User_isAdmin_isMember_isVendor_idx";
