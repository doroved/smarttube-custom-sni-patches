#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <path-to-SmartTube-repo>"
    echo "Example: $0 ../SmartTube"
    exit 1
fi

TARGET_DIR="$(cd "$1" && pwd)"
PATCH_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Applying Custom SNI patches to: $TARGET_DIR"

echo "[1/3] Applying SharedModules patch..."
git -C "$TARGET_DIR/SharedModules" apply --3way "$PATCH_DIR/01-sharedmodules-custom-sni.patch"

echo "[2/3] Applying MediaServiceCore patch..."
git -C "$TARGET_DIR/MediaServiceCore" apply --3way "$PATCH_DIR/02-mediaservicecore-custom-sni.patch"

echo "[3/3] Applying SmartTube main repo patch..."
git -C "$TARGET_DIR" apply --3way "$PATCH_DIR/03-smarttube-custom-sni.patch"

echo "Done! All Custom SNI patches applied successfully."
