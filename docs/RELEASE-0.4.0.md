# DroidConverge 0.4.0-dev prerelease

This is a debug-signed development build for testing the Android Bridge and
experimental external display companion. It is not a production-signed APK.

## APK

`DroidConvergeBridge-0.4.0-dev-debug.apk`

SHA-256: `c7816be367cdf7a006ab794772fcabf3f501eaf516fbe178f29e86fff047aa34`

The release also includes `DroidConvergeBridge-0.4.0-dev-debug.apk.sha256`.

## Included

- Internal Android panel with five display capability paths, sanitized
  diagnostics, and an optional companion surface on an Android presentation
  display.
- Opt-in Termux `RUN_COMMAND` control for a managed Anland/Plasma session.
  The helper uses `$PREFIX/bin/start-ubuntu-kde.sh` or, when absent, an
  executable `~/start-ubuntu-kde.sh`. Stop verifies the launcher and process
  identities before signalling Plasma and Anland.
- Wireless ADB installation support through `-DeviceSerial` in the PowerShell
  installer and a selective Maliit TCP haptic patch.

## Verified on RedMagic Astra

- Android 16 with a USB-C hub and AOC 24G4 monitor exposed a separate
  presentation display at 1920×1080. The app's companion content was captured
  from the HDMI display; in-app rollback removed its window.
- The panel reported an existing unmanaged Anland session as `UNKNOWN` and
  left it untouched. After that session ended, managed start, status, restart
  and stop worked. Restart produced new Anland and Plasma processes. Final
  stop left Anland, `plasma_session`, KWin and the socket absent.
- Clean `testDebugUnitTest` and `assembleDebug` succeeded with Gradle 9.6.0;
  the APK installed over wireless ADB and reported version `0.4.0-dev`.
  The Bridge Ping action returned `ok=true` and version `0.4.0-dev`.

## Limits and rollback

`plasmashell` was not observed in the managed sessions. The physical monitor
picture, keyboard/mouse input, hotplug and an extended KDE desktop were not
validated. Samsung DeX, Motorola Smart Connect and Pixel profiles remain
experimental. The Maliit patch was checked against its source backup but was
not built or runtime tested here.

Use `Solo interno (app)` to dismiss the companion surface. Stop a managed
session from the panel and confirm the helper reports `STOPPED`; an ambiguous
session returns `STOP_PENDING` and requires inspection in Termux. Restore the
previous Termux helper backup or remove the helper to disable panel control;
revoke DroidConverge's Termux `RUN_COMMAND` permission if no longer needed.
The `0.3.0-dev` debug APK can be reinstalled with `adb install -r -d` to allow
its lower versionCode for app rollback.
No permanent Android `wm`, resolution or density changes are made.
