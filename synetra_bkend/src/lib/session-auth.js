import { prisma } from "./prisma.js";
import {
  buildSessionExpiryDate,
  createSessionToken,
  extractBearerToken,
  hashSessionToken,
} from "./auth.js";

function normalizeIpAddress(ipAddress) {
  if (!ipAddress || typeof ipAddress !== "string") {
    return null;
  }

  return ipAddress.trim() || null;
}

function buildSessionPayload(session) {
  return {
    id: session.id,
    expiresAt: session.expiresAt,
    lastSeenAt: session.lastSeenAt,
  };
}

export function getRequestDeviceInfo(req) {
  const deviceInfoHeader = req.get("x-device-info") || req.get("x-device-name");
  return deviceInfoHeader?.trim() || null;
}

export async function createUserSession({ userId, req }) {
  const token = createSessionToken();
  const session = await prisma.userSession.create({
    data: {
      userId,
      tokenHash: hashSessionToken(token),
      deviceInfo: getRequestDeviceInfo(req),
      ipAddress: normalizeIpAddress(req.ip),
      userAgent: req.get("user-agent") || null,
      expiresAt: buildSessionExpiryDate(),
    },
  });

  return {
    token,
    session: buildSessionPayload(session),
  };
}

export async function resolveAuthenticatedSession(token) {
  if (!token) {
    return null;
  }

  const now = new Date();
  const session = await prisma.userSession.findUnique({
    where: {
      tokenHash: hashSessionToken(token),
    },
    include: {
      user: true,
    },
  });

  if (!session) {
    return null;
  }

  if (session.revokedAt || session.expiresAt <= now || !session.user.isActive) {
    return null;
  }

  if (now.getTime() - session.lastSeenAt.getTime() > 60 * 1000) {
    await prisma.userSession.update({
      where: { id: session.id },
      data: {
        lastSeenAt: now,
      },
    });
    session.lastSeenAt = now;
  }

  return session;
}

export async function attachSessionContext(req, res, next) {
  const token = extractBearerToken(req.get("authorization"));
  if (!token) {
    req.auth = null;
    return next();
  }

  try {
    const session = await resolveAuthenticatedSession(token);
    if (!session) {
      return res.status(401).json({
        error: "Session expired or invalid. Please sign in again.",
      });
    }

    req.auth = {
      token,
      user: session.user,
      session: buildSessionPayload(session),
    };
    return next();
  } catch (error) {
    return next(error);
  }
}

export function requireAuthenticatedSession(req, res, next) {
  if (!req.auth?.user || !req.auth?.session) {
    return res.status(401).json({
      error: "Authentication is required for this action.",
    });
  }

  return next();
}

export async function revokeSessionById(sessionId) {
  await prisma.userSession.update({
    where: { id: sessionId },
    data: {
      revokedAt: new Date(),
    },
  });
}
