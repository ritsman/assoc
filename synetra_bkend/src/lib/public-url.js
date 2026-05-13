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

  const forwardedProtoHeader = req.get("x-forwarded-proto") || "";
  const forwardedProto = forwardedProtoHeader.split(",")[0]?.trim();
  const protocol =
    forwardedProto || req.protocol || (req.secure ? "https" : "http");

  return `${protocol}://${req.get("host")}`;
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
