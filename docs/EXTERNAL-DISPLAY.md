# External display companion (experimental)

This work follows the `0.3.0-dev` prerelease. It does not change Android's
resolution, density, display mode, HOME role, or vendor settings. It does not
claim an extended KDE desktop.

## What is observed

On 2026-09-17, with no monitor connected, the RedMagic Astra (`nubia NP05J`,
Android 16) reported one logical display (ID 0), `1504x2400`, density `360`.
With the USB-C hub and AOC 24G4 monitor connected, wireless ADB reported two
physical and logical displays: the tablet (ID 0) and an HDMI display (ID 2,
1920x1080, density 213). Android gave ID 2 `FLAG_PRESENTATION`. The vendor
service reported HDMI ID 2 and `MirrorDisplayId=-1`; that vendor field alone
does not establish what pixels appeared on the monitor. In the app, pressing
`Stato su monitor` created a window on ID 2 while the app's controls remained
on ID 0. A capture of the physical HDMI display showed the expected
`DroidConverge Companion` text, without the tablet's controls. Pressing
`Solo interno (app)` removed that window from ID 2. This verifies Android's
secondary presentation surface and its rollback on the reference tablet.
The monitor panel itself was not independently inspected; KDE extension,
input and hotplug remain unverified. The temporary capture was deleted and
was not added to Git.

The app uses Android `DisplayManager` and its display listener. A presentation
display can receive a simple status surface when the user explicitly presses
the button. A physical mirror may have no separate logical display, so the app
cannot infer one from `DisplayManager` alone. The manual mirror and proprietary
desktop choices are marked experimental, are kept only for the current app
session, and never alter Android settings. Removal of an Android logical display
also clears the manual choice. A pure hardware mirror may not generate an
Android display event; use `Solo interno (app)` after disconnecting it.

| Path | Trigger | Behavior |
|---|---|---|
| `InternalOnly` | Only the default display is visible | Existing Bridge remains available |
| `MirrorCompanion` | User confirms mirror visually | Controls stay on tablet; no second surface is claimed |
| `SecondaryDisplayCompanion` | Android exposes a presentation display | Optional status surface on that display; KDE extension unverified |
| `DesktopEnvironmentDetected` | User explicitly reports a vendor desktop | Advisory controls only; no vendor automation |
| `UnsupportedOrUnknown` | Additional display without presentation capability | Safe diagnostic fallback |

The device family label is advisory. Samsung DeX, Motorola Ready For/Smart
Connect, Pixel and other Android devices remain untested. The RedMagic
`SecondaryDisplayCompanion` path has passed the Android surface test above;
the broader Anland/KDE session path remains experimental. On this tablet,
the `droidconverge-session` helper was installed with the Termux app UID and
the Android `RUN_COMMAND` permission was granted with the owner's approval.
`Aggiorna stato` returned `UNKNOWN`, because an Anland socket was already
present from a session not started by the helper. The panel did not start,
stop or restart that existing session. This confirms command delivery and the
conservative status response, not session lifecycle control.

## Session control setup

The panel uses Termux's documented `RUN_COMMAND` intent to call only the
installed `droidconverge-session` helper with `status`, `start`, `stop` or
`restart`. `scripts/install/install-termux.sh` copies that helper into Termux's
`$PREFIX/bin`; it does not install Termux, Anland, Ubuntu or enable external
commands. To opt in, set `allow-external-apps=true` in the local
`~/.termux/termux.properties`, run `termux-reload-settings`, and grant
`Run commands in Termux environment` to DroidConverge Bridge in Android app
permissions. This permission permits broad Termux command execution, so grant
it only if you trust the installed APK. The app does not change that property
or grant the permission automatically.

The helper stores a PID in Termux's private state directory and sends TERM only
to the launcher process it recorded and verified. `STOP_REQUESTED` means a
signal was sent, not that KDE stopped. `UNKNOWN` or `STOP_PENDING` requires
manual inspection in Termux. Restart refuses to start another session unless
the managed session appears stopped. Existing sessions started outside this
helper are never killed. A cable disconnect does not automatically stop KDE.
`STARTED` likewise confirms command dispatch, not a healthy KDE picture.

## Repeatable tablet verification

Build `0.4.0-dev` from `DroidConvergeBridge` with:

```powershell
.\gradlew.bat testDebugUnitTest assembleDebug
```

Run `adb devices` and confirm `device`, then install
`app/build/outputs/apk/debug/app-debug.apk` with `adb install -r`. This updates
the app without clearing its data. Keep a local copy of the published
`0.3.0-dev` APK for rollback.

For a USB-C monitor, use Android Wireless debugging instead of a USB ADB cable.
Pair the laptop in Developer options, read the `_adb-tls-connect._tcp` address
from `adb mdns services`, run `adb connect <tablet-ip>:<connect-port>`, and use
`adb -s <tablet-ip>:<connect-port>` for every command below. Both devices must
remain on the same Wi-Fi. Confirm `adb devices -l` says `device` before testing.

1. Keep the monitor disconnected.
2. Read `adb shell wm size`, `adb shell wm density`, and
   `adb shell dumpsys display`. Record only display count, IDs, type, mode,
   mirror/HDMI status and orientation; remove unique display IDs and logs.
3. Connect the working USB-C to HDMI/DisplayPort adapter and powered monitor.
   Repeat the same read-only commands. Observe whether the monitor mirrors the
   tablet or Android exposes a separate presentation display.
4. Open DroidConverge Bridge on the tablet. Check cable attach/detach updates,
   profile/path, status surface availability, and absence of crashes. For a
   confirmed mirror, choose the manual mirror option and verify controls remain
   usable on the tablet.
5. After installing the Termux helper and granting the permission, press
   `Aggiorna stato`. Start and stop only a new managed test session, confirming
   each action in the app. Inspect Anland socket, KDE picture, input, orientation
   and unplug behavior. Never stop an unrelated existing session.
6. Reconnect and repeat. Record adapter model, monitor resolution, touch/mouse/
   keyboard behavior and any vendor desktop prompt in `docs/DEVICE-PROFILES.md`.

Observed on the reference tablet: step 3 exposed a presentation display; the
presentation/rollback part of step 4 worked through wireless ADB; and the
status part of step 5 returned `UNKNOWN` for the pre-existing unmanaged Anland
session. Repeat with physical monitor inspection, hotplug and a new managed
session after the existing session ends before declaring the full workflow
tested. A mirror must never be labeled as extended KDE desktop.

Rollback: choose `Solo interno (app)` to dismiss the optional presentation and
clear the manual override. Stop a managed session only after checking its
status, or finish it through Termux. Unplug the monitor. If the new APK is
problematic, reinstall the verified `0.3.0-dev` APK with `adb install -r`;
restore the previous Termux helper from a local backup if it was replaced.
The Termux installer prints the local backup directory for overwritten files.
For this tablet's direct ADB installation, no previous helper existed: remove
`$PREFIX/bin/droidconverge-session` from Termux to roll it back. Revoke
`com.termux.permission.RUN_COMMAND` from DroidConverge Bridge in Android app
permissions, or run `adb shell pm revoke org.droidconverge.bridge
com.termux.permission.RUN_COMMAND`. Termux's pre-existing
`allow-external-apps=true` setting was left unchanged. No `wm` values need
restoring because this feature never writes them.

## Related work and attribution

[MagicDesk](https://github.com/mekhontsev/magicdesk) demonstrates a useful
phone control panel and independent displays. Its implementation includes
privileged Android services and X11 behavior that DroidConverge does not copy
or claim. MagicDesk's repository is [MIT licensed](https://github.com/mekhontsev/magicdesk/blob/main/LICENSE);
this feature was implemented independently with public Android display APIs
and Termux's documented command intent. The exact `RUN_COMMAND` setup and
result contract are documented by [Termux](https://github.com/termux/termux-app/wiki/RUN_COMMAND-Intent).
