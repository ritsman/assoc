CREATE TABLE "AssociationGalleryItem" (
  "id" TEXT NOT NULL,
  "associationId" TEXT NOT NULL,
  "imageUrl" TEXT,
  "headline" TEXT NOT NULL,
  "tagline" TEXT,
  "description" TEXT,
  "displayOrder" INTEGER NOT NULL DEFAULT 0,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,

  CONSTRAINT "AssociationGalleryItem_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "AssociationGalleryItem_associationId_displayOrder_idx"
ON "AssociationGalleryItem"("associationId", "displayOrder");

ALTER TABLE "AssociationGalleryItem"
ADD CONSTRAINT "AssociationGalleryItem_associationId_fkey"
FOREIGN KEY ("associationId") REFERENCES "Association"("id")
ON DELETE CASCADE ON UPDATE CASCADE;
