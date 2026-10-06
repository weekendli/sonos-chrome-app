#!/bin/bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$PROJECT_ROOT/build/Sonos.app"
DEST="$HOME/Applications/Sonos.app"
STAMP="$(date +%Y%m%d-%H%M%S)-$$"
LOG_DIR="$HOME/Library/Logs/Sonos Chrome App"
BACKUP=""
[[ -x "$SOURCE/Contents/MacOS/SonosLauncher" ]] || { echo "Run bash scripts/build.sh first." >&2; exit 1; }
# Avoid replacing the executable of a running embedded helper.
if pgrep -f "$DEST/Contents/Helpers/Sonos Controller.app/Contents/MacOS/SonosController" >/dev/null; then
 echo "Exit the menu bar controller using its power icon, then run this installer again." >&2
 exit 1
fi
mkdir -p "$HOME/Applications" "$LOG_DIR"
STAGED="$HOME/Applications/.Sonos-install-$STAMP.app"
ditto "$SOURCE" "$STAGED"
codesign --verify --deep "$STAGED"
if [[ -e "$DEST" ]]; then
 BACKUP="$HOME/Library/Application Support/Sonos Chrome App/Backups/Sonos-$STAMP.app"
 mkdir -p "$(dirname "$BACKUP")"
 mv "$DEST" "$BACKUP"
fi
if ! mv "$STAGED" "$DEST"; then
 [[ -z "$BACKUP" ]] || mv "$BACKUP" "$DEST"
 echo "Install failed; the previous launcher was restored." >&2
 exit 1
fi
printf '%s Installed %s; previous app backup: %s\n' "$(date -Iseconds)" "$DEST" "${BACKUP:-none}" >> "$LOG_DIR/install.log"
echo "Installed: $DEST"
[[ -z "$BACKUP" ]] || echo "Previous app backup: $BACKUP"
echo "Next: node scripts/setup-web-app.mjs (or --restart to restart an existing dedicated Chrome)."
