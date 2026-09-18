# External display companion (experimental)

## RedMagic extended-screen workflow observed after 0.4.0-dev

The owner confirmed that Anland reaches the external screen by opening Anland
and choosing **Schermo esteso** in RedMagic's display settings. The app's
`Stato app sul monitor` button shows only its own Android presentation and
does not move Anland. The panel also opens Anland and Android display settings
as separate steps toward RedMagic's manual `Schermo esteso` option.
Current read-only ADB output again shows the internal display and a separate
1920x1080 HDMI display (logical ID 6 at this connection), and Android input
reports an external USB keyboard and mice. This confirms Android sees the
hardware, not that KDE receives every input event. The app now lists external
input devices on the internal panel and opens Android input-method or Bluetooth
settings. Android's public input API does not provide a general control to
assign a keyboard or mouse to a particular display.
To use KDE on the monitor, launch Anland, use RedMagic's **Schermo esteso**, then
check monitor pixels and mouse/keyboard behavior manually. To roll back, move
Anland to the tablet in RedMagic settings, dismiss the app presentation with
`Solo interno (app)`, and stop the managed session if needed. No `wm` value is
changed by DroidConverge.

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
After the wireless ADB session changed, Android assigned the HDMI display ID
6 instead of 2. Display IDs are session values, not stable profile keys.

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
the broader Anland/KDE desktop path remains experimental. On this tablet,
the `droidconverge-session` helper was installed with the Termux app UID and
the Android `RUN_COMMAND` permission was granted with the owner's approval.
`Aggiorna stato` returned `UNKNOWN`, because an Anland socket was already
present from a session not started by the helper. The panel did not start,
stop or restart that existing session. This confirms command delivery and the
conservative status response. Later managed lifecycle tests are below.

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

The helper uses `$PREFIX/bin/start-ubuntu-kde.sh` when installed there. If it
is absent, it uses an executable `~/start-ubuntu-kde.sh`. This fallback was
needed on the reference tablet: the existing home launcher differs from the
repository copy and was not overwritten. An attempted start before the
fallback created no Anland process, socket or managed PID and the app showed
an unverified command. Keep the tablet's launcher under local ownership;
review it before using session control on another device.

The helper stores the launcher PID in Termux's private state directory.
During stop it requires a verified managed launcher, exactly one
`plasma_session`, exactly one Anland process that is a direct child of that
launcher, and root access for signalling Plasma. It sends TERM to Plasma,
waits for its exit, then sends TERM to that Anland process and waits for the
socket and launcher to disappear. If any identity check fails it returns
`STOP_PENDING` and leaves the processes for manual inspection. Existing
sessions started outside this helper are never killed. A cable disconnect
does not automatically stop KDE. `STARTED` confirms command dispatch; check
KDE separately. Restart refuses to start another session unless the managed
session appears stopped.

The first managed start with the home fallback reached Anland, KWin and a
running `plasma_session`, but `plasmashell` had not appeared during the
observation window. The former stop implementation only terminated the
launcher, leaving KDE and Anland active. The remaining processes were closed
manually with TERM before installing the revised stop logic.

The revised helper then passed a managed start and stop on the RedMagic:
Anland, `plasma_session` and KWin started; the helper reported `RUNNING`.
After pressing `Ferma`, those processes and the socket were absent and the
helper reported `STOPPED`. `plasmashell` was not observed during this test.
The panel initially displayed the earlier `STARTED` result after stop because
it refreshed before the asynchronous Termux result arrived. The updated app
shows a pending command state and refreshes after short and longer delays.
On the tablet, a subsequent status request displayed `STOPPED`, and the final
stop displayed `STOP_REQUESTED` while independent process checks confirmed
`STOPPED`.

The full managed start, restart and final stop were then exercised from the
Android panel. After restart, the Anland and Plasma process IDs changed and
the helper returned `RUNNING`. Final stop removed Anland, `plasma_session`,
KWin and the socket and returned `STOPPED` from the helper. No test session
was left running. `plasmashell` was still absent, so a complete KDE desktop
picture on the monitor is not claimed. The USB keyboard and mouse were
connected but input behavior was not measured.

On the reference tablet an earlier, unmanaged `start-ubuntu-kde.sh` process
remained alive after closing Anland's UI. `plasma_session`, KWin and
`plasmashell` were still running, and the Anland socket still had a listener.
Sending TERM to the single KWin process did not close KDE because
`kwin_wayland_wrapper` restarted it. Sending TERM to the single
`plasma_session` process closed KDE and KWin, while Anland and its socket
remained. This is an observed shutdown sequence, not an automated stop path:
do not assume that closing the UI, terminating KWin, or seeing a stale socket
means the full session is gone. The Ubuntu chroot installation itself did not
need a restart. Before a managed test, check the Anland listener and existing
KDE processes; close the old session in Termux first. Do not launch a second
KDE instance while they are present.

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
If ADB becomes `offline` and mDNS no longer advertises a connect service,
wake the tablet, confirm Wi-Fi and Wireless debugging are enabled, then read
the current connect endpoint and reconnect. The port may change. Never infer
that Anland stopped just because ADB disconnected.

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
managed start/status/stop/restart path in step 5 completed without residual
Anland/KWin/Plasma processes. Repeat with physical monitor inspection,
keyboard/mouse input and hotplug before declaring the full desktop workflow
tested. A mirror must never be labeled as extended KDE desktop.

Rollback: choose `Solo interno (app)` to dismiss the optional presentation and
clear the manual override. Stop a managed session only after checking its
status, or finish it through Termux. Unplug the monitor. If the new APK is
problematic, reinstall the verified `0.3.0-dev` debug APK with
`adb install -r -d` to allow its lower versionCode;
restore the previous Termux helper from a local backup if it was replaced.
The Termux installer prints the local backup directory for overwritten files.
For this tablet's direct ADB installation, a previous helper copy was retained
as `$PREFIX/bin/droidconverge-session.pre-stop-fix`; restore it only after
stopping any managed session, or remove the helper to disable panel control.
The previous copy has the incomplete stop behavior described above; use it
only for diagnosis. Revoke
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
