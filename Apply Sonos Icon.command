#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
PROFILE="$HOME/Library/Application Support/Sonos Chrome App"
WEB_APP="$HOME/Applications/Chrome Apps.localized/Sonos.app"
trap 'status=$?; if [[ -t 0 ]]; then if [[ $status -eq 0 ]]; then read -r -p "Press Return to close this window. " _; else read -r -p "Setup stopped. Press Return to close this window. " _; fi; fi' EXIT

[[ -d "$WEB_APP" ]] || { echo "Chrome has not created ~/Applications/Chrome Apps.localized/Sonos.app yet. Install Sonos as a Chrome web app first." >&2; exit 1; }
INSTALLED_PROFILE="$(/usr/bin/plutil -extract CrAppModeUserDataDir raw -o - "$WEB_APP/Contents/Info.plist" 2>/dev/null | tr -d '\n')" || { echo "Could not verify which Chrome profile owns the Sonos app; the icon was not changed." >&2; exit 1; }
case "$INSTALLED_PROFILE" in
  "$PROFILE"|"$PROFILE"/*) ;;
  *) echo "The Sonos app belongs to a different Chrome profile; its icon was not changed." >&2; exit 1 ;;
esac

"$ROOT/build/tools/set-icon" "$WEB_APP" "$ROOT/assets/Sonos.icns"
echo "Applied the Sonos icon to the dedicated Chrome app."
