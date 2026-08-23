#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="$ROOT_DIR/native-launcher"
OUTPUT_DIR="$ROOT_DIR/outputs"
TEMP_DIR="$(mktemp -d '/tmp/sky-go-fixed-distribution.XXXXXX')"
INSTALLER_APP="$TEMP_DIR/Installa Sky Go Fixed.app"
INSTALLER_CONTENTS="$INSTALLER_APP/Contents"
INSTALLER_MACOS="$INSTALLER_CONTENTS/MacOS"
INSTALLER_RESOURCES="$INSTALLER_CONTENTS/Resources"
DMG_FOLDER="$TEMP_DIR/Sky Go Fixed Installer"
DMG_PATH="$TEMP_DIR/Sky-Go-Fixed-Installer-macOS-26.dmg"
ZIP_PATH="$TEMP_DIR/Sky-Go-Fixed-Installer-macOS-26.zip"

cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

swift build --package-path "$PROJECT_DIR" -c release --arch arm64
swift build --package-path "$PROJECT_DIR" -c release --arch x86_64

ARM64_BIN="$PROJECT_DIR/.build/arm64-apple-macosx/release"
X86_BIN="$PROJECT_DIR/.build/x86_64-apple-macosx/release"

mkdir -p "$INSTALLER_MACOS" "$INSTALLER_RESOURCES" "$DMG_FOLDER" "$OUTPUT_DIR"

lipo -create \
  "$ARM64_BIN/SkyGoFixedInstaller" \
  "$X86_BIN/SkyGoFixedInstaller" \
  -output "$INSTALLER_MACOS/SkyGoFixedInstaller"
lipo -create \
  "$ARM64_BIN/SkyGoFixedLauncher" \
  "$X86_BIN/SkyGoFixedLauncher" \
  -output "$INSTALLER_RESOURCES/SkyGoFixedLauncher"

cp "$ROOT_DIR/distribution/InstallerInfo.plist" "$INSTALLER_CONTENTS/Info.plist"
cp "$ROOT_DIR/distribution/install.sh" "$INSTALLER_RESOURCES/install.sh"
cp "$ROOT_DIR/distribution/install-application.sh" "$INSTALLER_RESOURCES/install-application.sh"
cp "$ROOT_DIR/native-launcher/Resources/Info.plist" "$INSTALLER_RESOURCES/SkyGoFixedInfo.plist"
cp "$ROOT_DIR/native-launcher/Resources/SkyGo.icns" "$INSTALLER_RESOURCES/SkyGo.icns"
cp "$ROOT_DIR/distribution/skygo-compat.js" "$INSTALLER_RESOURCES/skygo-compat.js"

chmod 755 \
  "$INSTALLER_MACOS/SkyGoFixedInstaller" \
  "$INSTALLER_RESOURCES/SkyGoFixedLauncher" \
  "$INSTALLER_RESOURCES/install-application.sh" \
  "$INSTALLER_RESOURCES/install.sh"

xattr -cr "$INSTALLER_APP"
codesign --force --deep --sign - "$INSTALLER_APP"
codesign --verify --deep --strict "$INSTALLER_APP"

ditto "$INSTALLER_APP" "$DMG_FOLDER/Installa Sky Go Fixed.app"
cp "$ROOT_DIR/distribution/LEGGIMI.txt" "$DMG_FOLDER/PRIMA DI APRIRE - LEGGIMI.txt"

hdiutil create \
  -volname 'Sky Go Fixed' \
  -srcfolder "$DMG_FOLDER" \
  -format UDZO \
  -ov \
  "$DMG_PATH" >/dev/null

ditto -c -k --keepParent "$DMG_FOLDER" "$ZIP_PATH"

cp "$DMG_PATH" "$OUTPUT_DIR/Sky-Go-Fixed-Installer-macOS-26.dmg"
cp "$ZIP_PATH" "$OUTPUT_DIR/Sky-Go-Fixed-Installer-macOS-26.zip"

shasum -a 256 \
  "$OUTPUT_DIR/Sky-Go-Fixed-Installer-macOS-26.dmg" \
  "$OUTPUT_DIR/Sky-Go-Fixed-Installer-macOS-26.zip"
