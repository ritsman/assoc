ALTER TABLE "Member"
ADD COLUMN "committeePost" TEXT,
ADD COLUMN "committeeTenureStart" TIMESTAMP(3),
ADD COLUMN "committeeTenureEnd" TIMESTAMP(3),
ADD COLUMN "memberBio" TEXT;
