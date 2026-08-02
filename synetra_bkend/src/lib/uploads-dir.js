import path from "path";

const defaultUploadsDirPath = path.resolve(process.cwd(), "uploads");

export function getUploadsDirPath() {
  const configuredPath = process.env.UPLOADS_DIR?.trim();
  if (!configuredPath) {
    return defaultUploadsDirPath;
  }

  return path.resolve(configuredPath);
}

export function getUploadSubdirPath(...segments) {
  return path.join(getUploadsDirPath(), ...segments);
}
