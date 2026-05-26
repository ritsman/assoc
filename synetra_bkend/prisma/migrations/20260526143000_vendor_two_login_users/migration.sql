ALTER TABLE "User" DROP CONSTRAINT "User_vendorId_key";

CREATE INDEX "User_vendorId_idx" ON "User"("vendorId");
