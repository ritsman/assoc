-- AlterTable
ALTER TABLE "Association"
ADD COLUMN "headOfficeAddress" TEXT,
ADD COLUMN "city" TEXT,
ADD COLUMN "state" TEXT,
ADD COLUMN "pincode" TEXT,
ADD COLUMN "registrationNumber" TEXT,
ADD COLUMN "gstNumber" TEXT,
ADD COLUMN "website" TEXT,
ADD COLUMN "contactNumbers" JSONB,
ADD COLUMN "helpdeskNumber" TEXT,
ADD COLUMN "googleMapsLink" TEXT;

-- CreateTable
CREATE TABLE "AssociationRegionalAddress" (
    "id" TEXT NOT NULL,
    "associationId" TEXT NOT NULL,
    "label" TEXT,
    "officeAddress" TEXT,
    "city" TEXT,
    "state" TEXT,
    "pincode" TEXT,
    "registrationNumber" TEXT,
    "gstNumber" TEXT,
    "website" TEXT,
    "contactNumbers" JSONB,
    "helpdeskNumber" TEXT,
    "googleMapsLink" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "AssociationRegionalAddress_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "AssociationRegionalAddress_associationId_idx" ON "AssociationRegionalAddress"("associationId");

-- AddForeignKey
ALTER TABLE "AssociationRegionalAddress" ADD CONSTRAINT "AssociationRegionalAddress_associationId_fkey" FOREIGN KEY ("associationId") REFERENCES "Association"("id") ON DELETE CASCADE ON UPDATE CASCADE;
