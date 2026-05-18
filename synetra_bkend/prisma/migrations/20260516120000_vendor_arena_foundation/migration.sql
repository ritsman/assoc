ALTER TABLE "User"
ADD COLUMN "vendorId" TEXT;

CREATE TYPE "VendorStatus" AS ENUM ('PENDING', 'ACTIVE', 'SUSPENDED', 'LAPSED');

CREATE TABLE "Vendor" (
    "id" TEXT NOT NULL,
    "associationId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "companyName" TEXT NOT NULL,
    "contactPerson" TEXT,
    "email" TEXT NOT NULL,
    "phone" TEXT,
    "whatsapp" TEXT,
    "address" TEXT,
    "city" TEXT,
    "vendorType" TEXT,
    "category" TEXT,
    "onboardingStartAt" TIMESTAMP(3),
    "onboardingEndAt" TIMESTAMP(3),
    "membershipPlan" TEXT,
    "paymentStatus" "PaymentStatus" NOT NULL DEFAULT 'PENDING',
    "paymentAmount" TEXT,
    "paymentDueDate" TIMESTAMP(3),
    "badge" TEXT,
    "notes" TEXT,
    "status" "VendorStatus" NOT NULL DEFAULT 'PENDING',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Vendor_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "User_vendorId_key" ON "User"("vendorId");
CREATE UNIQUE INDEX "Vendor_associationId_email_key" ON "Vendor"("associationId", "email");
CREATE INDEX "Vendor_associationId_createdAt_idx" ON "Vendor"("associationId", "createdAt");
CREATE INDEX "Vendor_associationId_status_idx" ON "Vendor"("associationId", "status");

ALTER TABLE "User"
ADD CONSTRAINT "User_vendorId_fkey"
FOREIGN KEY ("vendorId") REFERENCES "Vendor"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "Vendor"
ADD CONSTRAINT "Vendor_associationId_fkey"
FOREIGN KEY ("associationId") REFERENCES "Association"("id") ON DELETE CASCADE ON UPDATE CASCADE;
