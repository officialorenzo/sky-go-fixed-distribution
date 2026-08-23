#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="$ROOT_DIR/native-launcher"
APP_BUNDLE="/Applications/Sky Go Fixed.app"
APP_MACOS="$APP_BUNDLE/Contents/MacOS"
APP_RESOURCES="$APP_BUNDLE/Contents/Resources"
RUNTIME_APP="$APP_RESOURCES/Sky Go Fixed Runtime.app"
RUNTIME_EXECUTABLE="$RUNTIME_APP/Contents/MacOS/Electron"
LAUNCHER_NAME="SkyGoFixedLauncher"

stop_app() {
  while IFS= read -r pid; do
    [[ -n "$pid" ]] && kill -TERM "$pid" 2>/dev/null || true
  done < <(pgrep -f "^$APP_MACOS/$LAUNCHER_NAME$" || true)
  while IFS= read -r pid; do
    [[ -n "$pid" ]] && kill -TERM "$pid" 2>/dev/null || true
  done < <(pgrep -f "^$RUNTIME_EXECUTABLE$" || true)

  for _ in {1..100}; do
    pgrep -f "^$APP_BUNDLE/Contents/" >/dev/null 2>&1 || return 0
    sleep 0.1
  done
}

build_app() {
  [[ -d "$APP_BUNDLE" ]] || { echo "Sky Go Fixed non è installata in Applicazioni." >&2; exit 1; }
  [[ -d "$RUNTIME_APP" ]] || { echo "Il motore interno non è presente." >&2; exit 1; }

  swift build --package-path "$PROJECT_DIR" -c release --arch arm64
  swift build --package-path "$PROJECT_DIR" -c release --arch x86_64

  local launcher_binary="$PROJECT_DIR/.build/SkyGoFixedLauncher-universal"
  lipo -create \
    "$PROJECT_DIR/.build/arm64-apple-macosx/release/$LAUNCHER_NAME" \
    "$PROJECT_DIR/.build/x86_64-apple-macosx/release/$LAUNCHER_NAME" \
    -output "$launcher_binary"

  ditto "$launcher_binary" "$APP_MACOS/$LAUNCHER_NAME"
  ditto "$PROJECT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
  ditto "$PROJECT_DIR/Resources/SkyGo.icns" "$APP_RESOURCES/SkyGo.icns"
  ditto "$ROOT_DIR/distribution/skygo-compat.js" "$APP_RESOURCES/skygo-compat.js"
  ditto "$PROJECT_DIR/Resources/SkyGo.icns" "$RUNTIME_APP/Contents/Resources/SkyGo.icns"
  chmod 755 "$APP_MACOS/$LAUNCHER_NAME"

  /usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier com.skygofixed.unofficial.runtime.v3' "$RUNTIME_APP/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c 'Set :CFBundleDisplayName Sky Go Fixed' "$RUNTIME_APP/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c 'Set :CFBundleName Sky Go Fixed' "$RUNTIME_APP/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c 'Set :CFBundleIconFile SkyGo.icns' "$RUNTIME_APP/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c 'Set :LSUIElement true' "$RUNTIME_APP/Contents/Info.plist" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c 'Add :LSUIElement bool true' "$RUNTIME_APP/Contents/Info.plist"

  xattr -cr "$APP_BUNDLE"
  codesign --force --deep --sign - "$RUNTIME_APP"
  xattr -cr "$APP_BUNDLE"
  codesign --force --deep --sign - "$APP_BUNDLE"
  codesign --verify --deep --strict "$APP_BUNDLE"
}

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

stop_app
build_app

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_MACOS/$LAUNCHER_NAME"
    ;;
  --logs|logs|--telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact \
      --predicate 'process == "SkyGoFixedLauncher" OR process == "Electron"'
    ;;
  --verify|verify)
    open_app
    for _ in {1..60}; do
      if pgrep -f "^$RUNTIME_EXECUTABLE$" >/dev/null 2>&1; then
        echo "Sky Go Fixed avviata."
        exit 0
      fi
      sleep 1
    done
    echo "Il motore Sky Go non è rimasto in esecuzione." >&2
    exit 1
    ;;
  *)
    echo "uso: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
