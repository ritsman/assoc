import {
  createHash,
  randomBytes,
  scrypt as scryptCallback,
  timingSafeEqual,
} from "crypto";
import { promisify } from "util";

const scrypt = promisify(scryptCallback);

export const PENDING_PASSWORD_PREFIX = "pending-password-setup";
const PASSWORD_SCHEME = "password";
const DEFAULT_MEMBER_PASSWORD_SCHEME = "default-member";
export const DEFAULT_MEMBER_PASSWORD =
  process.env.DEFAULT_MEMBER_PASSWORD || "Member@123";
export const BULK_MEMBER_DEFAULT_PASSWORD =
  process.env.BULK_MEMBER_DEFAULT_PASSWORD || "Nima@123";
const DEFAULT_ACCESS_TOKEN_TTL_MINUTES = Number(
  process.env.AUTH_ACCESS_TOKEN_TTL_MINUTES || 15,
);
const DEFAULT_REFRESH_TOKEN_TTL_HOURS = Number(
  process.env.AUTH_REFRESH_TOKEN_TTL_HOURS || 24 * 30,
);

export function buildPendingPasswordHash() {
  return `${PENDING_PASSWORD_PREFIX}:${randomBytes(16).toString("hex")}`;
}

async function hashWithScheme(password, scheme) {
  const salt = randomBytes(16).toString("hex");
  const derivedKey = await scrypt(password, salt, 64);
  return `${scheme}$${salt}$${Buffer.from(derivedKey).toString("hex")}`;
}

export async function hashPassword(password) {
  return hashWithScheme(password, PASSWORD_SCHEME);
}

export async function buildDefaultMemberPasswordHash(
  password = DEFAULT_MEMBER_PASSWORD,
) {
  return hashWithScheme(password, DEFAULT_MEMBER_PASSWORD_SCHEME);
}

export async function verifyPassword(password, storedHash) {
  if (!storedHash || storedHash.startsWith(`${PENDING_PASSWORD_PREFIX}:`)) {
    return false;
  }

  const parts = storedHash.split("$");
  if (parts.length === 3) {
    const [, salt, expectedHex] = parts;
    const derivedKey = Buffer.from(await scrypt(password, salt, 64));
    const expectedKey = Buffer.from(expectedHex, "hex");
    return (
      derivedKey.length === expectedKey.length &&
      timingSafeEqual(derivedKey, expectedKey)
    );
  }

  return storedHash === password;
}

export function isDefaultMemberPasswordHash(storedHash) {
  return storedHash.startsWith(`${DEFAULT_MEMBER_PASSWORD_SCHEME}$`);
}

export function createSessionToken() {
  return `sts_${randomBytes(32).toString("hex")}`;
}

export function hashSessionToken(token) {
  return createHash("sha256").update(token).digest("hex");
}

export function buildSessionExpiryDate() {
  return new Date(Date.now() + DEFAULT_ACCESS_TOKEN_TTL_MINUTES * 60 * 1000);
}

export function buildRefreshTokenExpiryDate() {
  return new Date(Date.now() + DEFAULT_REFRESH_TOKEN_TTL_HOURS * 60 * 60 * 1000);
}

export function extractBearerToken(headerValue) {
  if (!headerValue || typeof headerValue !== "string") {
    return null;
  }

  const [scheme, token] = headerValue.split(" ");
  if (!scheme || !token || scheme.toLowerCase() !== "bearer") {
    return null;
  }

  return token.trim() || null;
}
