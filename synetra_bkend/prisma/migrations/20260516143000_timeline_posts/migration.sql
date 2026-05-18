CREATE TYPE "TimelineSourceType" AS ENUM ('ASSOCIATION', 'MEMBER', 'VENDOR');

CREATE TABLE "TimelinePost" (
  "id" TEXT NOT NULL,
  "associationId" TEXT NOT NULL,
  "sourceType" "TimelineSourceType" NOT NULL,
  "memberId" TEXT,
  "vendorId" TEXT,
  "caption" TEXT NOT NULL,
  "imageUrl" TEXT,
  "imageType" TEXT,
  "landingPageUrl" TEXT,
  "youtubeUrl" TEXT,
  "facebookUrl" TEXT,
  "brochureUrl" TEXT,
  "brochureMimeType" TEXT,
  "reviewStatus" "PostReviewStatus" NOT NULL DEFAULT 'PENDING',
  "displayStart" TIMESTAMP(3),
  "displayEnd" TIMESTAMP(3),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,

  CONSTRAINT "TimelinePost_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "TimelinePost_associationId_createdAt_idx" ON "TimelinePost"("associationId", "createdAt");
CREATE INDEX "TimelinePost_sourceType_createdAt_idx" ON "TimelinePost"("sourceType", "createdAt");
CREATE INDEX "TimelinePost_reviewStatus_idx" ON "TimelinePost"("reviewStatus");

ALTER TABLE "TimelinePost"
ADD CONSTRAINT "TimelinePost_associationId_fkey"
FOREIGN KEY ("associationId") REFERENCES "Association"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "TimelinePost"
ADD CONSTRAINT "TimelinePost_memberId_fkey"
FOREIGN KEY ("memberId") REFERENCES "Member"("id")
ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "TimelinePost"
ADD CONSTRAINT "TimelinePost_vendorId_fkey"
FOREIGN KEY ("vendorId") REFERENCES "Vendor"("id")
ON DELETE SET NULL ON UPDATE CASCADE;
