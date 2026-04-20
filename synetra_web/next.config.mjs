import path from "path";

/** @type {import('next').NextConfig} */
const nextConfig = {
  typedRoutes: false,
  outputFileTracingRoot: path.join(process.cwd(), ".."),
  devIndicators: false,
};

export default nextConfig;
