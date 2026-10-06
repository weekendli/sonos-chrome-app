#!/bin/bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$PROJECT_ROOT/VERSION")"
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "VERSION must contain a three-part numeric version." >&2
  exit 1
fi

APP="$PROJECT_ROOT/build/Sonos.app"
ICON_TOOL="$PROJECT_ROOT/build/tools/set-icon"
DIST="$PROJECT_ROOT/dist"
PAYLOAD="$DIST/Sonos-macOS-v$VERSION"
ZIP="$DIST/Sonos-macOS-v$VERSION.zip"
SUMS="$DIST/SHA256SUMS"

[[ -d "$APP" && -x "$APP/Contents/MacOS/SonosLauncher" ]] || { echo "Build the app first: bash scripts/build.sh" >&2; exit 1; }
[[ -x "$ICON_TOOL" ]] || { echo "The prebuilt icon tool is missing: $ICON_TOOL" >&2; exit 1; }
if [[ -e "$PAYLOAD" || -e "$ZIP" || -e "$SUMS" ]]; then
  echo "A release output already exists in dist/. Move it aside before packaging again." >&2
  exit 1
fi

codesign --verify --deep --strict "$APP"
mkdir -p "$PAYLOAD/build/tools" "$PAYLOAD/scripts" "$PAYLOAD/assets"
ditto "$APP" "$PAYLOAD/build/Sonos.app"
install -m 755 "$ICON_TOOL" "$PAYLOAD/build/tools/set-icon"
cp "$PROJECT_ROOT/scripts/install.sh" "$PAYLOAD/scripts/install.sh"
cp "$PROJECT_ROOT/assets/Sonos.icns" "$PAYLOAD/assets/Sonos.icns"
cp "$PROJECT_ROOT/LICENSE" "$PAYLOAD/LICENSE"
cp "$PROJECT_ROOT/NOTICE.md" "$PAYLOAD/NOTICE.md"
cp "$PROJECT_ROOT/README-Install.md" "$PAYLOAD/README-Install.md"
cp "$PROJECT_ROOT/Install Sonos.command" "$PAYLOAD/Install Sonos.command"
cp "$PROJECT_ROOT/Apply Sonos Icon.command" "$PAYLOAD/Apply Sonos Icon.command"
chmod 755 "$PAYLOAD/Install Sonos.command" "$PAYLOAD/Apply Sonos Icon.command"

ditto -c -k --sequesterRsrc --keepParent "$PAYLOAD" "$ZIP"
(cd "$DIST" && shasum -a 256 "$(basename "$ZIP")" > "$(basename "$SUMS")")
echo "Created: $ZIP"
echo "Created: $SUMS"
