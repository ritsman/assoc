-- AlterTable
ALTER TABLE "Vendor" ALTER COLUMN "updatedAt" DROP DEFAULT;

-- CreateTable
CREATE TABLE "AppBanner" (
    "id" TEXT NOT NULL,
    "associationId" TEXT NOT NULL,
    "vendorId" TEXT,
    "shortText" TEXT NOT NULL,
    "contactNumber" TEXT,
    "mediaUrl" TEXT,
    "mediaType" TEXT,
    "brochureUrl" TEXT,
    "brochureMimeType" TEXT,
    "socialMediaUrl" TEXT,
    "reviewStatus" "PostReviewStatus" NOT NULL DEFAULT 'PENDING',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "AppBanner_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "AppBanner_associationId_createdAt_idx" ON "AppBanner"("associationId", "createdAt");

-- CreateIndex
CREATE INDEX "AppBanner_reviewStatus_idx" ON "AppBanner"("reviewStatus");

-- AddForeignKey
ALTER TABLE "AppBanner" ADD CONSTRAINT "AppBanner_associationId_fkey" FOREIGN KEY ("associationId") REFERENCES "Association"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AppBanner" ADD CONSTRAINT "AppBanner_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "Vendor"("id") ON DELETE SET NULL ON UPDATE CASCADE;
