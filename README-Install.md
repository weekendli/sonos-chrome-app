# Sonos for macOS — Preview v0.1.0

This archive contains a prebuilt universal app for Apple silicon and Intel Macs.
It does not require Xcode Command Line Tools, Python, Node.js, or a source build.

## Install

1. Download `Sonos-macOS-v0.1.0.zip` and `SHA256SUMS` from the
   [v0.1.0 preview release](https://github.com/weekendli/sonos-chrome-app/releases/tag/v0.1.0).
2. Put both files in the same folder and verify the archive in Terminal:

   ```bash
   shasum -a 256 -c SHA256SUMS
   ```

3. Unzip the archive and double-click **Install Sonos.command**. The installer
   backs up an existing `~/Applications/Sonos.app` before replacing it and
   opens the Sonos site in a normal Chrome window using a separate profile.
4. In that Chrome window, sign in if prompted. Choose **More → Cast, save, and
   share → Install page as app**. Confirm Chrome creates the app named **Sonos**.
5. Double-click **Apply Sonos Icon.command**. It verifies that the Chrome app
   belongs to the dedicated Sonos profile before changing its icon.
6. Open `~/Applications/Sonos.app`. It starts the menu bar controller and the
   Sonos web app.

The Chrome app lives at `~/Applications/Chrome Apps.localized/Sonos.app`. Its
profile and Sonos sign-in are stored separately at
`~/Library/Application Support/Sonos Chrome App`.

## macOS security

This preview uses an ad hoc signature and is not notarized with Apple. The
SHA-256 file detects archive corruption; it does not identify the publisher. If
you choose to run the preview and macOS blocks the app, first try to open it,
then use **System Settings → Privacy & Security → Open Anyway** to approve that
app. Do not disable Gatekeeper globally. See [Apple's instructions for safely
opening apps](https://support.apple.com/en-sg/102445).

## Requirements and current limits

- macOS 13 or later.
- Google Chrome at `/Applications/Google Chrome.app`.
- A Sonos system on the same local network; SSDP discovery requires multicast.
- This v0.1.0 preview has not been installed on a fresh macOS profile.

The controller uses Sonos devices' LAN UPnP/SOAP services. It does not use a
Sonos cloud API credential. See `NOTICE.md` for third-party notices and
`LICENSE` for the MIT license.

## Restore or remove

To restore an earlier launcher, exit the controller and move the current
`~/Applications/Sonos.app` aside. Restore the timestamped copy under
`~/Library/Application Support/Sonos Chrome App/Backups/`.

To remove the app, uninstall the Sonos web app in the dedicated Chrome profile,
then move `~/Applications/Sonos.app` to the Trash. Removing the profile also
removes its local Sonos sign-in.
