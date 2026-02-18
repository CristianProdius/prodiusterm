import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  devIndicators: false,
  output: "standalone",
  serverExternalPackages: ["node-pty", "better-sqlite3"],
};

export default nextConfig;
