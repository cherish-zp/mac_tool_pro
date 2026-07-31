#!/bin/bash
#
# Official build path: uses Xcode + your Apple Development certificate (auto-signing).
# The signed Finder Sync extension will register with the system (unlike ad-hoc).
#
# Requirements:
#   - Working Xcode at /Applications/Xcode.app
#       sudo xcode-select -s /Applications/Xcode.app
#       sudo xcodebuild -license accept
#   - Apple ID added in Xcode > Settings > Accounts (a free Apple ID is fine)
#   - xcodegen installed:  brew install xcodegen
#
set -euo pipefail
cd "$(dirname "$0")"

echo "▸ Detecting Apple Development team..."
LINE=$(security find-identity -v -p codesigning | grep -m1 'Apple Development' || true)
TEAM=$(echo "$LINE" | grep -oE '\([0-9A-Z]{10}\)' | tail -1 | tr -d '()')
if [ -z "$TEAM" ]; then
  echo "error: no 'Apple Development' identity found." >&2
  echo "Add your Apple ID in Xcode > Settings > Accounts, then retry." >&2
  exit 1
fi
echo "  team: $TEAM  ($LINE)"

command -v xcodegen >/dev/null || { echo "error: xcodegen missing. Run: brew install xcodegen" >&2; exit 1; }

echo "▸ Generating Xcode project..."
xcodegen generate

echo "▸ Building (Release, automatic signing)..."
xcodebuild -project mac_tool_pro.xcodeproj \
  -scheme mac_tool_pro \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  DEVELOPMENT_TEAM="$TEAM" \
  CODE_SIGN_STYLE=Automatic \
  build | tail -20

APP=$(find "$HOME/Library/Developer/Xcode/DerivedData" -maxdepth 5 -path '*Build/Products/Release/mac_tool_pro.app' 2>/dev/null | head -1)
if [ -z "$APP" ]; then
  echo "error: could not locate built mac_tool_pro.app in DerivedData" >&2
  exit 1
fi
echo "  built: $APP"

echo "▸ Packaging DMG..."
STAGE="$(mktemp -d)"
ditto "$APP" "$STAGE/mac_tool_pro.app"
ln -s /Applications "$STAGE/Applications"
mkdir -p dist
hdiutil create -volname mac_tool_pro -srcfolder "$STAGE" -ov -format UDZO dist/mac_tool_pro-1.0.0.dmg >/dev/null
rm -rf "$STAGE"

echo "✓ Done: $(pwd)/dist/mac_tool_pro-1.0.0.dmg"
echo "  Install: open the DMG, drag to /Applications, launch the app, then enable the"
echo "  extension in System Settings > Privacy & Security > Extensions > Finder Extensions."
