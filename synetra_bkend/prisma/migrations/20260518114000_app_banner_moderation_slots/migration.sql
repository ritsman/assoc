ALTER TABLE "AppBanner"
ADD COLUMN "paymentReceived" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN "paymentMode" TEXT,
ADD COLUMN "paymentRemarks" TEXT,
ADD COLUMN "displayStart" TIMESTAMP(3),
ADD COLUMN "displayEnd" TIMESTAMP(3),
ADD COLUMN "displayIndex" INTEGER,
ADD COLUMN "approvedAt" TIMESTAMP(3);

CREATE INDEX "AppBanner_displayIndex_idx" ON "AppBanner"("displayIndex");
