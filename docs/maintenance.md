# Maintenance and removal

## Rebuild

```bash
bash scripts/build.sh
# Exit the menu controller before replacing its bundle.
bash scripts/install.sh
```

## Restore a previous launcher

The installer prints a timestamped backup path. Exit the controller, then copy
that backup over `~/Applications/Sonos.app` using Finder or `ditto`. Browser
profile and speaker preferences are preserved.

## Reapply the app icon / standalone mode

```bash
node scripts/setup-web-app.mjs --restart
```

The setup affects only the dedicated Sonos profile. A Sonos app shim registered
with another profile causes setup to stop rather than redirect that app.

## Remove

1. Exit the controller and quit the Sonos web app.
2. Uninstall the Sonos web app from Chrome's app management for the dedicated
   profile. This lets Chrome remove its app registration and generated shim.
3. Move the native `~/Applications/Sonos.app` launcher to the Trash.
4. Optionally remove the dedicated profile, artwork cache and controller
   preference after making any desired backup. Removing the browser profile
   also removes the local Sonos login session.

## Read current state

For local diagnostics only, the controller binary accepts:

```bash
"$HOME/Applications/Sonos.app/Contents/Helpers/Sonos Controller.app/Contents/MacOS/SonosController" --read-state
```

This prints current room/music/status to the terminal and does not send playback
commands. Do not publish its output if it contains information you want private.

The `--diagnostics` flag is intended for development and writes a private local
JSON status file. Normal startup does not enable it.

## Current verification scope

The original local app's native popover, LAN state retrieval, current artwork,
standalone Sonos process identity and icon were observed on Apple silicon/macOS
26. Source compilation is separate from runtime verification on other machines.
The extracted project's installer and setup helper are included for
reproducibility and have not been run against a fresh macOS user/profile.
