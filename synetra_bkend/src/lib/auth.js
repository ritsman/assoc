import { randomBytes, scrypt as scryptCallback, timingSafeEqual } from "crypto";
import { promisify } from "util";

const scrypt = promisify(scryptCallback);

export const PENDING_PASSWORD_PREFIX = "pending-password-setup";
const PASSWORD_SCHEME = "password";
const DEFAULT_MEMBER_PASSWORD_SCHEME = "default-member";
export const DEFAULT_MEMBER_PASSWORD =
  process.env.DEFAULT_MEMBER_PASSWORD || "Member@123";
export const BULK_MEMBER_DEFAULT_PASSWORD =
  process.env.BULK_MEMBER_DEFAULT_PASSWORD || "Nima@123";

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
