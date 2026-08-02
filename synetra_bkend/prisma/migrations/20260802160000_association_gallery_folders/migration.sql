-- CreateTable
CREATE TABLE "AssociationGalleryFolder" (
    "id" TEXT NOT NULL,
    "associationId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "AssociationGalleryFolder_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AssociationGalleryPhoto" (
    "id" TEXT NOT NULL,
    "folderId" TEXT NOT NULL,
    "imageUrl" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "AssociationGalleryPhoto_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "AssociationGalleryFolder_associationId_createdAt_idx" ON "AssociationGalleryFolder"("associationId", "createdAt");

-- CreateIndex
CREATE INDEX "AssociationGalleryPhoto_folderId_createdAt_idx" ON "AssociationGalleryPhoto"("folderId", "createdAt");

-- AddForeignKey
ALTER TABLE "AssociationGalleryFolder" ADD CONSTRAINT "AssociationGalleryFolder_associationId_fkey" FOREIGN KEY ("associationId") REFERENCES "Association"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AssociationGalleryPhoto" ADD CONSTRAINT "AssociationGalleryPhoto_folderId_fkey" FOREIGN KEY ("folderId") REFERENCES "AssociationGalleryFolder"("id") ON DELETE CASCADE ON UPDATE CASCADE;
