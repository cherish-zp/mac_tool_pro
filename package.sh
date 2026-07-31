#!/bin/bash
#
# Packages mac_tool_pro into an installable DMG (drag-to-Applications).
# Builds with Xcode automatic signing, then creates dist/mac_tool_pro-<version>.dmg.
#
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="mac_tool_pro"
DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-77SQ3JU8MG}"
DERIVED="build/DerivedData"
APP="$DERIVED/Build/Products/Release/${APP_NAME}.app"

echo "▸ Xcode build (automatic signing, team $DEVELOPMENT_TEAM)..."
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -project mac_tool_pro.xcodeproj -scheme mac_tool_pro \
    -configuration Release -destination 'generic/platform=macOS' \
    -derivedDataPath "$DERIVED" \
    DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" CODE_SIGN_STYLE=Automatic \
    clean build >/tmp/mac_tool_pro_build.log 2>&1

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Contents/Info.plist")
DMG_DIR="dist"
DMG="${DMG_DIR}/${APP_NAME}-${VERSION}.dmg"

echo "▸ Verifying code signature..."
codesign --verify --verbose=4 "$APP" >/dev/null 2>&1 || { echo "✗ Signature verification failed"; exit 1; }

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
