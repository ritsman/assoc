CREATE TABLE "AssociationNewsBulletinDocument" (
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

  CONSTRAINT "AssociationNewsBulletinDocument_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "AssociationNewsBulletinDocument_associationId_displayOrder_idx"
ON "AssociationNewsBulletinDocument"("associationId", "displayOrder");

ALTER TABLE "AssociationNewsBulletinDocument"
ADD CONSTRAINT "AssociationNewsBulletinDocument_associationId_fkey"
FOREIGN KEY ("associationId") REFERENCES "Association"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

CREATE TABLE "AssociationMagazineDocument" (
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

  CONSTRAINT "AssociationMagazineDocument_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "AssociationMagazineDocument_associationId_displayOrder_idx"
ON "AssociationMagazineDocument"("associationId", "displayOrder");

ALTER TABLE "AssociationMagazineDocument"
ADD CONSTRAINT "AssociationMagazineDocument_associationId_fkey"
FOREIGN KEY ("associationId") REFERENCES "Association"("id")
ON DELETE CASCADE ON UPDATE CASCADE;
