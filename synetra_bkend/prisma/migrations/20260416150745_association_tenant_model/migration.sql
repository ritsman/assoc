-- DropForeignKey
ALTER TABLE "Association" DROP CONSTRAINT "Association_clientId_fkey";

-- DropForeignKey
ALTER TABLE "Member" DROP CONSTRAINT "Member_clientId_fkey";

-- DropIndex
DROP INDEX "Association_clientId_idx";

-- DropIndex
DROP INDEX "Association_clientId_slug_key";

-- DropIndex
DROP INDEX "Member_clientId_email_key";

-- DropIndex
DROP INDEX "Member_clientId_idx";

-- AlterTable
ALTER TABLE "Association"
DROP COLUMN "clientId",
ADD COLUMN "appName" TEXT,
ADD COLUMN "domain" TEXT,
ADD COLUMN "isActive" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN "logoUrl" TEXT,
ADD COLUMN "primaryColor" TEXT;

-- AlterTable
ALTER TABLE "Member" DROP COLUMN "clientId";

-- DropTable
DROP TABLE "Client";

-- CreateIndex
CREATE UNIQUE INDEX "Association_slug_key" ON "Association"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "Association_domain_key" ON "Association"("domain");

-- CreateIndex
CREATE UNIQUE INDEX "Member_associationId_email_key" ON "Member"("associationId", "email");
