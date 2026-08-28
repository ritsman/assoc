CREATE TYPE "EventAttendeeType" AS ENUM ('MEMBER', 'VENDOR');

CREATE TYPE "EventPassStatus" AS ENUM ('ACTIVE', 'USED', 'CANCELLED');

CREATE TABLE "EventAttendance" (
  "id" TEXT NOT NULL,
  "associationId" TEXT NOT NULL,
  "eventId" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "memberId" TEXT,
  "vendorId" TEXT,
  "attendeeType" "EventAttendeeType" NOT NULL,
  "attendeeName" TEXT NOT NULL,
  "attendeeEmail" TEXT NOT NULL,
  "companyName" TEXT,
  "participantCount" INTEGER NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,

  CONSTRAINT "EventAttendance_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "EventPass" (
  "id" TEXT NOT NULL,
  "associationId" TEXT NOT NULL,
  "eventId" TEXT NOT NULL,
  "attendanceId" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "memberId" TEXT,
  "vendorId" TEXT,
  "attendeeType" "EventAttendeeType" NOT NULL,
  "passCode" TEXT NOT NULL,
  "attendeeName" TEXT NOT NULL,
  "attendeeEmail" TEXT NOT NULL,
  "companyName" TEXT,
  "slotNumber" INTEGER NOT NULL,
  "participantCount" INTEGER NOT NULL,
  "status" "EventPassStatus" NOT NULL DEFAULT 'ACTIVE',
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,

  CONSTRAINT "EventPass_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "EventAttendance_eventId_userId_key"
ON "EventAttendance"("eventId", "userId");

CREATE UNIQUE INDEX "EventPass_passCode_key"
ON "EventPass"("passCode");

CREATE INDEX "EventAttendance_associationId_eventId_idx"
ON "EventAttendance"("associationId", "eventId");

CREATE INDEX "EventAttendance_userId_createdAt_idx"
ON "EventAttendance"("userId", "createdAt");

CREATE INDEX "EventPass_associationId_eventId_idx"
ON "EventPass"("associationId", "eventId");

CREATE INDEX "EventPass_attendanceId_slotNumber_idx"
ON "EventPass"("attendanceId", "slotNumber");

CREATE INDEX "EventPass_userId_createdAt_idx"
ON "EventPass"("userId", "createdAt");

ALTER TABLE "EventAttendance"
ADD CONSTRAINT "EventAttendance_associationId_fkey"
FOREIGN KEY ("associationId") REFERENCES "Association"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "EventAttendance"
ADD CONSTRAINT "EventAttendance_eventId_fkey"
FOREIGN KEY ("eventId") REFERENCES "AssociationEvent"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "EventAttendance"
ADD CONSTRAINT "EventAttendance_userId_fkey"
FOREIGN KEY ("userId") REFERENCES "User"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "EventAttendance"
ADD CONSTRAINT "EventAttendance_memberId_fkey"
FOREIGN KEY ("memberId") REFERENCES "Member"("id")
ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "EventAttendance"
ADD CONSTRAINT "EventAttendance_vendorId_fkey"
FOREIGN KEY ("vendorId") REFERENCES "Vendor"("id")
ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "EventPass"
ADD CONSTRAINT "EventPass_associationId_fkey"
FOREIGN KEY ("associationId") REFERENCES "Association"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "EventPass"
ADD CONSTRAINT "EventPass_eventId_fkey"
FOREIGN KEY ("eventId") REFERENCES "AssociationEvent"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "EventPass"
ADD CONSTRAINT "EventPass_attendanceId_fkey"
FOREIGN KEY ("attendanceId") REFERENCES "EventAttendance"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "EventPass"
ADD CONSTRAINT "EventPass_userId_fkey"
FOREIGN KEY ("userId") REFERENCES "User"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "EventPass"
ADD CONSTRAINT "EventPass_memberId_fkey"
FOREIGN KEY ("memberId") REFERENCES "Member"("id")
ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "EventPass"
ADD CONSTRAINT "EventPass_vendorId_fkey"
FOREIGN KEY ("vendorId") REFERENCES "Vendor"("id")
ON DELETE SET NULL ON UPDATE CASCADE;
