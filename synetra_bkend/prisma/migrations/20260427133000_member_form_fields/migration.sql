-- CreateEnum
CREATE TYPE "PaymentStatus" AS ENUM ('PENDING', 'PAID', 'OVERDUE', 'WAIVED');

-- AlterTable
ALTER TABLE "Member"
ADD COLUMN "address" TEXT,
ADD COLUMN "customFieldValues" JSONB,
ADD COLUMN "gst" TEXT,
ADD COLUMN "membershipDetails" TEXT,
ADD COLUMN "membershipEndDate" TIMESTAMP(3),
ADD COLUMN "membershipStartDate" TIMESTAMP(3),
ADD COLUMN "paymentAmount" TEXT,
ADD COLUMN "paymentStatus" "PaymentStatus" NOT NULL DEFAULT 'PENDING';
