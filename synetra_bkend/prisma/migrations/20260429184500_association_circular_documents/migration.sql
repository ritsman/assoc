CREATE TABLE "AssociationCircularDocument" (
  "id" TEXT NOT NULL,
  "associationId" TEXT NOT NULL,
  "headline" TEXT NOT NULL,
  "tagline" TEXT,
  "summary" TEXT,
  "originalFileName" TEXT NOT NULL,
  "storedFileName" TEXT NOT NULL,
  "storagePath" TEXT NOT NULL,
  "mimeType" TEXT NOT NULL,
  "fileSize" INTEGER NOT NULL,
  "displayOrder" INTEGER NOT NULL DEFAULT 0,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,

  CONSTRAINT "AssociationCircularDocument_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "AssociationCircularDocument_associationId_displayOrder_idx"
ON "AssociationCircularDocument"("associationId", "displayOrder");

ALTER TABLE "AssociationCircularDocument"
ADD CONSTRAINT "AssociationCircularDocument_associationId_fkey"
FOREIGN KEY ("associationId") REFERENCES "Association"("id")
ON DELETE CASCADE ON UPDATE CASCADE;
