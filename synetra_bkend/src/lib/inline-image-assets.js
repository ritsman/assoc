import crypto from "crypto";
import fs from "fs";
import path from "path";

const mimeExtensionMap = new Map([
  ["image/jpeg", "jpg"],
  ["image/png", "png"],
  ["image/webp", "webp"],
  ["image/gif", "gif"],
  ["image/svg+xml", "svg"],
  ["image/avif", "avif"],
  ["image/bmp", "bmp"],
]);

export function isInlineDataImageUrl(value) {
  return /^data:image\/[a-z0-9.+-]+;base64,/i.test(String(value || "").trim());
}

export function persistInlineImageDataUrl({
  dataUrl,
  uploadsDirPath,
  publicPathPrefix,
  fallbackBaseName,
}) {
  if (typeof dataUrl === "undefined") {
    return undefined;
  }

  const rawValue = String(dataUrl || "").trim();
  if (!isInlineDataImageUrl(rawValue)) {
    return rawValue;
  }

  const matches = rawValue.match(/^data:(image\/[a-z0-9.+-]+);base64,(.+)$/i);
  if (!matches) {
    return rawValue;
  }

  const [, mimeType, base64Payload] = matches;
  const extension = mimeExtensionMap.get(mimeType.toLowerCase()) || "bin";
  const fileName = `${Date.now()}-${fallbackBaseName}-${crypto.randomBytes(6).toString("hex")}.${extension}`;

  fs.mkdirSync(uploadsDirPath, { recursive: true });
  fs.writeFileSync(
    path.join(uploadsDirPath, fileName),
    Buffer.from(base64Payload, "base64"),
  );

  return `${publicPathPrefix.replace(/\/+$/, "")}/${fileName}`;
}

export function deleteLocalAssetIfPresent(fileValue, uploadsSegment) {
  const rawValue = String(fileValue || "").trim();
  if (!rawValue || rawValue.startsWith("data:")) {
    return;
  }

  let normalizedPath = rawValue;
  if (/^https?:\/\//i.test(rawValue)) {
    try {
      normalizedPath = new URL(rawValue).pathname.replace(/^\/+/, "");
    } catch {
      normalizedPath = rawValue;
    }
  }

  const expectedPrefix = `${uploadsSegment.replace(/^\/+/, "").replace(/\/+$/, "")}/`;
  if (!normalizedPath.startsWith(expectedPrefix)) {
    return;
  }

  const filePath = path.resolve(process.cwd(), normalizedPath);
  if (fs.existsSync(filePath)) {
    fs.unlinkSync(filePath);
  }
}
