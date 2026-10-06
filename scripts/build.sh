#!/bin/bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
APP="$BUILD_DIR/Sonos.app"
CONTROLLER="$APP/Contents/Helpers/Sonos Controller.app"
VERSION=1.0.0
if [[ "$(uname -s)" != Darwin ]]; then
  echo "This project builds on macOS." >&2
  exit 1
fi
xcrun --find clang >/dev/null
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" \
  "$CONTROLLER/Contents/MacOS" "$CONTROLLER/Contents/Resources" "$BUILD_DIR/tools"
ARCH_ARGS=()
for ARCH in ${ARCHS:-$(uname -m)}; do
  case "$ARCH" in arm64|x86_64) ARCH_ARGS+=(-arch "$ARCH");; *) echo "Unsupported architecture: $ARCH" >&2; exit 1;; esac
done
xcrun clang -fobjc-arc -mmacosx-version-min=13.0 "${ARCH_ARGS[@]}" -framework AppKit \
  "$PROJECT_ROOT/src/launcher.m" -o "$APP/Contents/MacOS/SonosLauncher"
xcrun clang -fobjc-arc -mmacosx-version-min=13.0 "${ARCH_ARGS[@]}" -framework AppKit \
  "$PROJECT_ROOT/src/controller.m" "$PROJECT_ROOT/src/SonosLANClient.m" \
  -o "$CONTROLLER/Contents/MacOS/SonosController"
xcrun clang -fobjc-arc -mmacosx-version-min=13.0 "${ARCH_ARGS[@]}" -framework AppKit \
  "$PROJECT_ROOT/src/set-icon.m" -o "$BUILD_DIR/tools/set-icon"
cp "$PROJECT_ROOT/assets/Sonos.icns" "$APP/Contents/Resources/Sonos.icns"
cp "$PROJECT_ROOT/assets/Sonos.icns" "$CONTROLLER/Contents/Resources/Sonos.icns"
cp "$PROJECT_ROOT/assets/sonos-menubar.png" "$CONTROLLER/Contents/Resources/sonos-menubar.png"
python3 - "$APP" "$CONTROLLER" "$VERSION" <<'PLIST'
import plistlib,sys
from pathlib import Path
app,controller,version=map(str,sys.argv[1:])
def info(name,identifier,executable):
 return dict(CFBundleDevelopmentRegion='en',CFBundleName=name,CFBundleDisplayName=name,
  CFBundleIdentifier=identifier,CFBundleExecutable=executable,CFBundleIconFile='Sonos.icns',
  CFBundlePackageType='APPL',CFBundleInfoDictionaryVersion='6.0',
  CFBundleShortVersionString=version,CFBundleVersion='1',LSMinimumSystemVersion='13.0',LSUIElement=True)
main=info('Sonos','local.ops.sonos-launcher','SonosLauncher')
helper=info('Sonos Controller','local.ops.sonos-controller','SonosController')
helper.update(NSAppTransportSecurity={'NSAllowsLocalNetworking':True},
 NSLocalNetworkUsageDescription='Sonos Controller connects to your Sonos speakers to display the current song and control playback.')
for path,data in [(app,main),(controller,helper)]:
 (Path(path)/'Contents/Info.plist').write_bytes(plistlib.dumps(data))
PLIST
codesign --force --sign - "$CONTROLLER"
codesign --force --sign - "$APP"
echo "Built: $APP"
