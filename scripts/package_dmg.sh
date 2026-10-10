#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_PATH="$BUILD_DIR/NovaPlayer.app"
DMG_NAME="NovaPlayer.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"
TEMP_DMG_DIR="$BUILD_DIR/dmg_temp"

echo "==> Ensuring NovaPlayer.app is built..."
if [ ! -d "$APP_PATH" ]; then
    "$PROJECT_DIR/scripts/build_app.sh"
fi

echo "==> Preparing DMG folder structure..."
rm -rf "$TEMP_DMG_DIR" "$DMG_PATH"
mkdir -p "$TEMP_DMG_DIR"

# Copy App
cp -R "$APP_PATH" "$TEMP_DMG_DIR/NovaPlayer.app"

# Create symlink to /Applications for standard drag-and-drop installer
ln -s /Applications "$TEMP_DMG_DIR/Applications"

echo "==> Creating DMG image: $DMG_PATH..."
hdiutil create -volname "NovaPlayer" \
    -srcfolder "$TEMP_DMG_DIR" \
    -ov -format UDZO \
    "$DMG_PATH"

rm -rf "$TEMP_DMG_DIR"

echo "==> Successfully created $DMG_PATH"
ls -lh "$DMG_PATH"
