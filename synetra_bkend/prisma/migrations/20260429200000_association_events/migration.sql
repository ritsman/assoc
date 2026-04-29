CREATE TABLE "AssociationEventType" (
  "id" TEXT NOT NULL,
  "associationId" TEXT NOT NULL,
  "name" TEXT NOT NULL,
  "description" TEXT NOT NULL,
  "displayOrder" INTEGER NOT NULL DEFAULT 0,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,

  CONSTRAINT "AssociationEventType_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "AssociationEventType_associationId_displayOrder_idx"
ON "AssociationEventType"("associationId", "displayOrder");

ALTER TABLE "AssociationEventType"
ADD CONSTRAINT "AssociationEventType_associationId_fkey"
FOREIGN KEY ("associationId") REFERENCES "Association"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

CREATE TABLE "AssociationEvent" (
  "id" TEXT NOT NULL,
  "associationId" TEXT NOT NULL,
  "name" TEXT NOT NULL,
  "type" TEXT NOT NULL,
  "audience" TEXT,
  "entryType" TEXT,
  "entryCharges" TEXT,
  "participationCharges" TEXT,
  "date" TIMESTAMP(3) NOT NULL,
  "venue" TEXT,
  "startTime" TEXT,
  "endTime" TEXT,
  "summary" TEXT,
  "bannerUrl" TEXT,
  "bannerFileName" TEXT,
  "promoVideoUrl" TEXT,
  "promoVideoFileName" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,

  CONSTRAINT "AssociationEvent_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "AssociationEvent_associationId_date_idx"
ON "AssociationEvent"("associationId", "date");

ALTER TABLE "AssociationEvent"
ADD CONSTRAINT "AssociationEvent_associationId_fkey"
FOREIGN KEY ("associationId") REFERENCES "Association"("id")
ON DELETE CASCADE ON UPDATE CASCADE;
