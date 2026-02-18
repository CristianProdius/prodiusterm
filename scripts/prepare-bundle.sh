#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUNDLE_DIR="$PROJECT_ROOT/src-tauri/server-bundle"

echo "=== ProdiusTerm: Preparing server bundle ==="
echo "Project root: $PROJECT_ROOT"

cd "$PROJECT_ROOT"

# 1. Rebuild native modules for current arch
echo "--- Rebuilding native modules ---"
pnpm rebuild node-pty better-sqlite3

# 2. Build Next.js (produces .next/standalone/)
echo "--- Building Next.js (standalone) ---"
pnpm build

# 3. Compile server.ts with esbuild
echo "--- Compiling server.ts ---"
pnpm exec esbuild server.ts --bundle --platform=node --target=node20 \
  --external:next --external:node-pty --external:better-sqlite3 --external:ws \
  --outfile=dist/server.js

# 4. Assemble server-bundle
echo "--- Assembling server-bundle ---"
rm -rf "$BUNDLE_DIR"
mkdir -p "$BUNDLE_DIR"

# Copy standalone output preserving symlinks as-is (don't dereference yet)
cp -R .next/standalone/ "$BUNDLE_DIR/"

# Strip pnpm internals — .pnpm dirs contain symlink targets we don't need
find "$BUNDLE_DIR" -type d -name ".pnpm" -prune -exec rm -rf {} + 2>/dev/null || true

# Remove ALL symlinks — resolve them to real files or delete broken ones
# Real packages we need (next, ws, etc.) are already in node_modules as real dirs
# from standalone output; only pnpm housekeeping symlinks remain
find "$BUNDLE_DIR" -type l -delete 2>/dev/null || true

# Overwrite with our compiled server entry point
cp dist/server.js "$BUNDLE_DIR/server.js"

# Copy static assets (Next.js standalone doesn't include .next/static)
mkdir -p "$BUNDLE_DIR/.next/static"
cp -R .next/static/ "$BUNDLE_DIR/.next/static/"

# Copy public assets if they exist
if [ -d "public" ]; then
  cp -R public/ "$BUNDLE_DIR/public/"
fi

# Ensure native modules are present with prebuilds (copy real files, deref symlinks)
# node-pty
if [ -d "node_modules/node-pty" ]; then
  rm -rf "$BUNDLE_DIR/node_modules/node-pty"
  mkdir -p "$BUNDLE_DIR/node_modules/node-pty"
  rsync -a --copy-links --ignore-errors node_modules/node-pty/ "$BUNDLE_DIR/node_modules/node-pty/" || true
fi

# better-sqlite3
if [ -d "node_modules/better-sqlite3" ]; then
  rm -rf "$BUNDLE_DIR/node_modules/better-sqlite3"
  mkdir -p "$BUNDLE_DIR/node_modules/better-sqlite3"
  rsync -a --copy-links --ignore-errors node_modules/better-sqlite3/ "$BUNDLE_DIR/node_modules/better-sqlite3/" || true
fi

# Final cleanup — remove any broken symlinks that slipped through
find "$BUNDLE_DIR" -type l -delete 2>/dev/null || true

# 5. Ad-hoc sign all .node native binaries (required before Tauri bundles them)
echo "--- Signing native binaries ---"
find "$BUNDLE_DIR" -name "*.node" -exec codesign --force --sign - {} \;

echo "=== Server bundle ready at $BUNDLE_DIR ==="
du -sh "$BUNDLE_DIR"
