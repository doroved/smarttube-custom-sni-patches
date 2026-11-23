#!/usr/bin/env bash
set -euo pipefail

PATCH_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="${1:-$PATCH_DIR/../SmartTube}"
PATCH_VER="${2:-$(tr -d '[:space:]' < "$PATCH_DIR/PATCH_VERSION")}"
if [ -n "${SMARTTUBE_JAVA_HOME:-}" ]; then
    JAVA_HOME_PATH="$SMARTTUBE_JAVA_HOME"
elif [ -d "/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home" ]; then
    JAVA_HOME_PATH="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
else
    JAVA_HOME_PATH="${JAVA_HOME:-}"
fi

if [ ! -d "$REPO_DIR/.git" ]; then
    echo "Error: SmartTube git repository not found at $REPO_DIR"
    exit 1
fi

if ! [[ "$PATCH_VER" =~ ^[0-9]+$ ]] || [ "$PATCH_VER" -lt 1 ] || [ "$PATCH_VER" -gt 999 ]; then
    echo "Error: PATCH_VERSION must be an integer between 1 and 999 (got: '$PATCH_VER')"
    exit 1
fi

BRANCH_NAME="$(git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD)"
if [ "$BRANCH_NAME" = "HEAD" ]; then
    BRANCH_NAME="$(git -C "$REPO_DIR" describe --tags --always)-doroved-patch"
fi

# Ensure keystore.properties is present in the repo root
cp "$PATCH_DIR/keystore.properties" "$REPO_DIR/keystore.properties"

echo "Running CustomSniTest and building signed ststableRelease APK (doroved-patch v${PATCH_VER})..."
(
    cd "$REPO_DIR"
    JAVA_HOME="$JAVA_HOME_PATH" ./gradlew \
        -PpatchVersion="$PATCH_VER" \
        :sharedutils:testDebugUnitTest --tests com.liskovsoft.sharedutils.okhttp.CustomSniTest \
        :smarttubetv:assembleStstableRelease
)

OUT_DIR="$PATCH_DIR/apks/${BRANCH_NAME}-v${PATCH_VER}"
mkdir -p "$OUT_DIR"

APK_SRC_DIR="$REPO_DIR/smarttubetv/build/outputs/apk/ststable/release"
for apk in "$APK_SRC_DIR"/*.apk; do
    base="$(basename "$apk")"
    # Insert _doroved-patch-v<N> before the last _<arch>.apk segment
    new_name="${base%_*}_doroved-patch-v${PATCH_VER}_${base##*_}"
    cp "$apk" "$OUT_DIR/$new_name"
done

echo ""
echo "Signed APKs (v${PATCH_VER}) saved to: $OUT_DIR"
ls -lh "$OUT_DIR"
