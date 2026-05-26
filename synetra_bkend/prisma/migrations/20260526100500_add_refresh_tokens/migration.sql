-- Add refresh token support to existing user sessions.
ALTER TABLE "UserSession"
ADD COLUMN "refreshTokenHash" TEXT,
ADD COLUMN "refreshExpiresAt" TIMESTAMP(3);

UPDATE "UserSession"
SET
  "refreshTokenHash" = "tokenHash",
  "refreshExpiresAt" = "expiresAt";

ALTER TABLE "UserSession"
ALTER COLUMN "refreshTokenHash" SET NOT NULL,
ALTER COLUMN "refreshExpiresAt" SET NOT NULL;

CREATE UNIQUE INDEX "UserSession_refreshTokenHash_key"
ON "UserSession"("refreshTokenHash");

CREATE INDEX "UserSession_refreshExpiresAt_revokedAt_idx"
ON "UserSession"("refreshExpiresAt", "revokedAt");
