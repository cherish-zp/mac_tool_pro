#!/bin/bash
#
# Packages mac_tool_pro into an installable DMG (drag-to-Applications).
# Runs build.sh first, then creates dist/mac_tool_pro-<version>.dmg.
#
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="mac_tool_pro"
APP="build/${APP_NAME}.app"

echo "▸ Clean build..."
rm -rf build
./build.sh >/dev/null

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Contents/Info.plist")
DMG_DIR="dist"
DMG="${DMG_DIR}/${APP_NAME}-${VERSION}.dmg"

echo "▸ Staging DMG contents (app + Applications link)..."
STAGE="$(mktemp -d)"
ditto "$APP" "$STAGE/${APP_NAME}.app"
ln -s /Applications "$STAGE/Applications"

echo "▸ Creating DMG..."
rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"

echo "▸ Verifying DMG..."
hdiutil verify "$DMG" >/dev/null
MNT="/tmp/mtg_${APP_NAME}_$$"
mkdir -p "$MNT"
hdiutil attach -nobrowse -mountpoint "$MNT" "$DMG" >/dev/null
echo "  DMG contents:"; ls -1 "$MNT" | sed 's/^/    /'
hdiutil detach "$MNT" >/dev/null
rmdir "$MNT" 2>/dev/null || true

echo "✓ Packaged: $(pwd)/$DMG"
echo "  Size: $(du -h "$DMG" | cut -f1)"
