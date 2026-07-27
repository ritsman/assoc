import { prisma } from "./prisma.js";
import {
  buildRefreshTokenExpiryDate,
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
    refreshExpiresAt: session.refreshExpiresAt,
    lastSeenAt: session.lastSeenAt,
  };
}

export function getRequestDeviceInfo(req) {
  const deviceInfoHeader = req.get("x-device-info") || req.get("x-device-name");
  return deviceInfoHeader?.trim() || null;
}

export async function createUserSession({ userId, req }) {
  const token = createSessionToken();
  const refreshToken = createSessionToken();
  const now = new Date();
  const session = await prisma.$transaction(async (tx) => {
    await tx.userSession.updateMany({
      where: {
        userId,
        revokedAt: null,
      },
      data: {
        revokedAt: now,
      },
    });

    return tx.userSession.create({
      data: {
        userId,
        tokenHash: hashSessionToken(token),
        refreshTokenHash: hashSessionToken(refreshToken),
        deviceInfo: getRequestDeviceInfo(req),
        ipAddress: normalizeIpAddress(req.ip),
        userAgent: req.get("user-agent") || null,
        expiresAt: buildSessionExpiryDate(),
        refreshExpiresAt: buildRefreshTokenExpiryDate(),
      },
    });
  });

  return {
    token,
    refreshToken,
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

export function requireAdminUser(req, res, next) {
  if (!req.auth?.user) {
    return res.status(401).json({
      error: "Authentication is required for this action.",
    });
  }

  if (!req.auth.user.isAdmin) {
    return res.status(403).json({
      error: "Admin access is required for this action.",
    });
  }

  return next();
}

export function requireSuperAdminUser(req, res, next) {
  if (!req.auth?.user) {
    return res.status(401).json({
      error: "Authentication is required for this action.",
    });
  }

  if (!req.auth.user.isSuperAdmin) {
    return res.status(403).json({
      error: "Super admin access is required for this action.",
    });
  }

  return next();
}

export async function resolveRefreshableSession(refreshToken) {
  if (!refreshToken) {
    return null;
  }

  const now = new Date();
  const session = await prisma.userSession.findUnique({
    where: {
      refreshTokenHash: hashSessionToken(refreshToken),
    },
    include: {
      user: true,
    },
  });

  if (!session) {
    return null;
  }

  if (
    session.revokedAt ||
    session.refreshExpiresAt <= now ||
    !session.user.isActive
  ) {
    return null;
  }

  return session;
}

export async function refreshUserSession({ refreshToken, req }) {
  const session = await resolveRefreshableSession(refreshToken);
  if (!session) {
    return null;
  }

  const nextToken = createSessionToken();
  const nextRefreshToken = createSessionToken();
  const now = new Date();

  const updatedSession = await prisma.userSession.update({
    where: { id: session.id },
    data: {
      tokenHash: hashSessionToken(nextToken),
      refreshTokenHash: hashSessionToken(nextRefreshToken),
      expiresAt: buildSessionExpiryDate(),
      refreshExpiresAt: buildRefreshTokenExpiryDate(),
      lastSeenAt: now,
      deviceInfo: getRequestDeviceInfo(req),
      ipAddress: normalizeIpAddress(req.ip),
      userAgent: req.get("user-agent") || null,
    },
  });

  return {
    token: nextToken,
    refreshToken: nextRefreshToken,
    session: buildSessionPayload(updatedSession),
    user: session.user,
  };
}

export async function revokeSessionById(sessionId) {
  await prisma.userSession.update({
    where: { id: sessionId },
    data: {
      revokedAt: new Date(),
    },
  });
}
