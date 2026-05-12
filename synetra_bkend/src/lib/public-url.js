function normalizeBaseUrl(rawBaseUrl) {
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

export function buildPublicAssetUrl(req, storagePath) {
  const normalizedPath = storagePath.replace(/^\/+/, "");
  const configuredBaseUrl = normalizeBaseUrl(process.env.PUBLIC_APP_URL);

  if (configuredBaseUrl) {
    return `${configuredBaseUrl}/${normalizedPath}`;
  }

  const forwardedProtoHeader = req.get("x-forwarded-proto") || "";
  const forwardedProto = forwardedProtoHeader.split(",")[0]?.trim();
  const protocol =
    forwardedProto || req.protocol || (req.secure ? "https" : "http");

  return `${protocol}://${req.get("host")}/${normalizedPath}`;
}
