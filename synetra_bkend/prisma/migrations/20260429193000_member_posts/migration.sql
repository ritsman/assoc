CREATE TYPE "PostReviewStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');

CREATE TABLE "MemberPost" (
  "id" TEXT NOT NULL,
  "memberId" TEXT NOT NULL,
  "associationId" TEXT NOT NULL,
  "title" TEXT NOT NULL,
  "summary" TEXT NOT NULL,
  "body" TEXT,
  "mediaUrl" TEXT,
  "mediaType" TEXT,
  "postType" TEXT,
  "reviewStatus" "PostReviewStatus" NOT NULL DEFAULT 'PENDING',
  "displayStart" TIMESTAMP(3),
  "displayEnd" TIMESTAMP(3),
  "approvedAt" TIMESTAMP(3),
  "rejectedAt" TIMESTAMP(3),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,

  CONSTRAINT "MemberPost_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "MemberPost_associationId_createdAt_idx" ON "MemberPost"("associationId", "createdAt");
CREATE INDEX "MemberPost_memberId_createdAt_idx" ON "MemberPost"("memberId", "createdAt");
CREATE INDEX "MemberPost_reviewStatus_idx" ON "MemberPost"("reviewStatus");

ALTER TABLE "MemberPost"
ADD CONSTRAINT "MemberPost_memberId_fkey"
FOREIGN KEY ("memberId") REFERENCES "Member"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "MemberPost"
ADD CONSTRAINT "MemberPost_associationId_fkey"
FOREIGN KEY ("associationId") REFERENCES "Association"("id")
ON DELETE CASCADE ON UPDATE CASCADE;
