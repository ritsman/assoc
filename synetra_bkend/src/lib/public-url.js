export function normalizeBaseUrl(rawBaseUrl) {
  const trimmed = rawBaseUrl?.trim();
  if (!trimmed) {
    return null;
  }

  try {
    const parsed = new URL(trimmed);
    return parsed.origin;
  } catch (_error) {
    return null;
  }
}

function resolveRequestBaseUrl(req) {
  const configuredBaseUrl = normalizeBaseUrl(process.env.PUBLIC_APP_URL);

  if (configuredBaseUrl) {
    return configuredBaseUrl;
  }

  const forwardedProtoHeader =
    req.get("x-forwarded-proto") ||
    req.get("x-forwarded-scheme") ||
    req.get("x-forwarded-ssl") ||
    "";
  const forwardedProto = forwardedProtoHeader.split(",")[0]?.trim().toLowerCase();
  const forwardedHostHeader = req.get("x-forwarded-host") || "";
  const forwardedHost = forwardedHostHeader.split(",")[0]?.trim();
  const forwardedPortHeader = req.get("x-forwarded-port") || "";
  const forwardedPort = forwardedPortHeader.split(",")[0]?.trim();
  const requestHost = forwardedHost || req.get("host");
  const originHeader = req.get("origin") || "";
  const refererHeader = req.get("referer") || "";
  const hostname = String(requestHost || "")
    .replace(/:\d+$/, "")
    .trim()
    .toLowerCase();
  const isLocalHost =
    hostname === "localhost" ||
    hostname === "127.0.0.1" ||
    hostname.endsWith(".local");
  const matchingSecureHeader = [originHeader, refererHeader]
    .map((value) => {
      try {
        return value ? new URL(value) : null;
      } catch (_error) {
        return null;
      }
    })
    .find((value) => value?.host === requestHost && value.protocol === "https:");
  const protocol =
    forwardedProto === "https" ||
    forwardedProto === "on" ||
    forwardedPort === "443" ||
    matchingSecureHeader
      ? "https"
      : forwardedProto || req.protocol || (req.secure ? "https" : isLocalHost ? "http" : "https");

  return `${protocol}://${requestHost}`;
}

export function buildPublicAssetUrl(req, storagePath) {
  const normalizedPath = String(storagePath || "").replace(/^\/+/, "");
  if (!normalizedPath) {
    return "";
  }

  return `${resolveRequestBaseUrl(req)}/${normalizedPath}`;
}

export function resolvePublicAssetUrl(req, value) {
  const rawValue = String(value || "").trim();
  if (!rawValue) {
    return "";
  }

  if (rawValue.startsWith("data:")) {
    return rawValue;
  }

  if (!/^https?:\/\//i.test(rawValue)) {
    return buildPublicAssetUrl(req, rawValue);
  }

  try {
    const parsedUrl = new URL(rawValue);
    const requestBaseUrl = new URL(resolveRequestBaseUrl(req));
    const normalizedPublicBaseUrl = normalizeBaseUrl(process.env.PUBLIC_APP_URL);
    const configuredHost =
      normalizedPublicBaseUrl ? new URL(normalizedPublicBaseUrl).host : null;
    const requestHost = requestBaseUrl.host;

    if (
      parsedUrl.host === requestHost ||
      (configuredHost && parsedUrl.host === configuredHost)
    ) {
      parsedUrl.protocol = requestBaseUrl.protocol;
      parsedUrl.host = requestBaseUrl.host;
      return parsedUrl.toString();
    }

    return rawValue;
  } catch (_error) {
    return rawValue;
  }
}

export function buildPublicThumbnailUrl(req, value) {
  return resolvePublicAssetUrl(req, value);
}
