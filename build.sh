#!/bin/bash
#
# Builds mac_tool_pro (menu bar app + Finder Sync extension) using swiftc directly,
# so it works without a full Xcode install. Produces build/mac_tool_pro.app.
#
set -euo pipefail

# --- Configuration ----------------------------------------------------------
SDK_NAME="MacOSX15.4.sdk"
SDK_PATH="${MAC_TOOL_PRO_SDK:-/Library/Developer/CommandLineTools/SDKs/$SDK_NAME}"
DEPLOYMENT_TARGET="13.0"
ARCH="arm64"

APP_NAME="mac_tool_pro"
EXT_NAME="FinderSyncExt"

ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT/build"
MODULE_CACHE="$BUILD_DIR/modulecache"

APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
EXT_BUNDLE="$APP_BUNDLE/Contents/PlugIns/$EXT_NAME.appex"

SHARED_DIR="$ROOT/Sources/Shared"
APP_SRC_DIR="$ROOT/Sources/App"
EXT_SRC_DIR="$ROOT/Sources/FinderSyncExt"

# --- Prep -------------------------------------------------------------------
echo "Using SDK: $SDK_PATH"
if [ ! -d "$SDK_PATH" ]; then
  echo "error: SDK not found at $SDK_PATH" >&2
  echo "Available SDKs:" >&2
  ls -1 /Library/Developer/CommandLineTools/SDKs/ 2>/dev/null | sed 's/^/  /' >&2
  echo "Set MAC_TOOL_PRO_SDK to an absolute SDK path, e.g.:" >&2
  echo "  MAC_TOOL_PRO_SDK=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk ./build.sh" >&2
  exit 1
fi
mkdir -p "$MODULE_CACHE"

COMMON_FLAGS=(
  -sdk "$SDK_PATH"
  -target "$ARCH-apple-macos$DEPLOYMENT_TARGET"
  -module-cache-path "$MODULE_CACHE"
  -O
)

# --- Build Finder Sync extension --------------------------------------------
echo "▸ Building $EXT_NAME..."
mkdir -p "$EXT_BUNDLE/Contents/MacOS"
swiftc "${COMMON_FLAGS[@]}" \
  -module-name "$EXT_NAME" \
  "$SHARED_DIR"/*.swift "$EXT_SRC_DIR"/*.swift \
  -framework FinderSync -framework AppKit -framework Foundation \
  -emit-executable -o "$EXT_BUNDLE/Contents/MacOS/$EXT_NAME"
cp "$ROOT/Resources/Ext-Info.plist" "$EXT_BUNDLE/Contents/Info.plist"
printf 'XPC!????' > "$EXT_BUNDLE/Contents/PkgInfo"

# --- Build main app ---------------------------------------------------------
echo "▸ Building $APP_NAME..."
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"
swiftc "${COMMON_FLAGS[@]}" \
  -module-name "$APP_NAME" \
  "$SHARED_DIR"/*.swift "$APP_SRC_DIR"/*.swift \
  -framework AppKit -framework Foundation \
  -emit-executable -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$ROOT/Resources/App-Info.plist" "$APP_BUNDLE/Contents/Info.plist"
printf 'APPL????' > "$APP_BUNDLE/Contents/PkgInfo"

# --- Sign (ad-hoc + hardened runtime; sign inner bundle first) --------------
echo "▸ Code signing (ad-hoc)..."
codesign --force --options runtime --sign - "$EXT_BUNDLE"
codesign --force --options runtime --sign - "$APP_BUNDLE"

echo "✓ Built: $APP_BUNDLE"
echo "  Launch it once to register the Finder extension, then enable it in"
echo "  System Settings > Privacy & Security > Extensions > Finder Extensions."
