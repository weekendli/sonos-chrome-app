#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
CHROME_APP="/Applications/Google Chrome.app"
PROFILE="$HOME/Library/Application Support/Sonos Chrome App"
WEB_APP="$HOME/Applications/Chrome Apps.localized/Sonos.app"
URL="https://play.sonos.com/en-us/web-app"
trap 'status=$?; if [[ -t 0 ]]; then if [[ $status -eq 0 ]]; then read -r -p "Press Return to close this window. " _; else read -r -p "Setup stopped. Press Return to close this window. " _; fi; fi' EXIT

[[ -x "$ROOT/build/Sonos.app/Contents/MacOS/SonosLauncher" ]] || { echo "The prebuilt Sonos app is missing. Re-extract the release ZIP and try again." >&2; exit 1; }
[[ -d "$CHROME_APP" ]] || { echo "Google Chrome must be installed at /Applications/Google Chrome.app." >&2; exit 1; }

NEEDS_PWA=1
if [[ -e "$WEB_APP" ]]; then
  INSTALLED_PROFILE="$(/usr/bin/plutil -extract CrAppModeUserDataDir raw -o - "$WEB_APP/Contents/Info.plist" 2>/dev/null | tr -d '\n')" || true
  case "$INSTALLED_PROFILE" in
    "$PROFILE"|"$PROFILE"/*)
      echo "An existing Sonos web app already belongs to the dedicated Sonos profile."
      NEEDS_PWA=0
      ;;
    *)
      echo "An existing Sonos web app belongs to another Chrome profile. No app or profile was changed." >&2
      echo "Move that Sonos app aside yourself if you want to install this dedicated-profile version." >&2
      exit 1
      ;;
  esac
fi

bash "$ROOT/scripts/install.sh"
if [[ "$NEEDS_PWA" -eq 1 ]]; then
  echo
  echo "Chrome is opening the Sonos site in a separate profile. In that window:"
  echo "  1. Sign in to Sonos if prompted."
  echo "  2. Choose More > Cast, save, and share > Install page as app."
  echo "  3. Confirm the app is named Sonos."
  echo "  4. After Chrome creates the app, run Apply Sonos Icon.command here."
  echo "  5. Open ~/Applications/Sonos.app to start Sonos and its menu bar controller."
  /usr/bin/open -na "$CHROME_APP" --args "--user-data-dir=$PROFILE" --no-first-run --no-default-browser-check --new-window "$URL"
fi
