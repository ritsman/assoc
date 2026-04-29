-- CreateTable
CREATE TABLE "AssociationAboutContent" (
    "id" TEXT NOT NULL,
    "associationId" TEXT NOT NULL,
    "heroTitle" TEXT,
    "heroIntro" TEXT,
    "missionTitle" TEXT,
    "missionText" TEXT,
    "goalsTitle" TEXT,
    "goalsText" TEXT,
    "journeyTitle" TEXT,
    "journeyText" TEXT,
    "headOfficeImage" TEXT,
    "galleryImageOne" TEXT,
    "galleryImageTwo" TEXT,
    "stats" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "AssociationAboutContent_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "AssociationAboutContent_associationId_key" ON "AssociationAboutContent"("associationId");

-- AddForeignKey
ALTER TABLE "AssociationAboutContent" ADD CONSTRAINT "AssociationAboutContent_associationId_fkey" FOREIGN KEY ("associationId") REFERENCES "Association"("id") ON DELETE CASCADE ON UPDATE CASCADE;
