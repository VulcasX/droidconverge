# DroidConverge installation

After granting DroidConverge Bridge the Termux RUN_COMMAND permission and
setting `allow-external-apps=true`, open Termux once before the first app
`Avvia` on RedMagic if its AutoLaunch policy blocks a cold service start.
The app reports that OEM block explicitly. A `KDE residuo senza Anland`
state means an old KDE process still occupies the Ubuntu chroot; review the
guarded `Ripara` procedure and rollback in `EXTERNAL-DISPLAY.md` before
starting again. The guided installer updates the managed session helper on a
future fast-forward checkout.

## External keyboard/mouse routing on RedMagic

The app's per-device `Su HDMI` and `Sul tablet` controls use a small
DroidConverge `app_process` helper with Magisk root. Grant root to the Bridge
app when prompted. Without root, the action reports an error and leaves the
device under Android's existing routing. Test one mouse first while the
tablet touchscreen remains available, then test the keyboard. `Rilascia tutti
gli input` returns app-owned routes to display 0. This is a runtime Android
association and does not install MagicDesk or change `wm` settings. See
`docs/EXTERNAL-DISPLAY.md` for the verified ADB check and rollback.

USB storage is a separate feature: the input controls do not mount a flash
drive inside Ubuntu. The peripheral panel now reports Android's removable
volume state, but does not mount it. If Android says `unmountable`, do not
format the drive as part of installation. Wi-Fi/Bluetooth status means the
radio is enabled; it does not confirm a paired cooler connection.

## Guided setup from the Android app (0.5.0-dev)

The app's **Avvia installazione guidata** button opens an interactive Termux
session through the documented `RUN_COMMAND` permission. It installs Git if
needed, clones the project's `codex/external-display` development branch into
`~/droidconverge`, and runs `scripts/install/install-system.sh --apply`.
Before any chroot writes, the script checks ARM64, root, Anland, the
`chroot-distro` command and an existing Ubuntu 26.04 `ubuntu26` rootfs. These
components must be installed from their reviewed upstream sources first; the
app does not silently flash a root module, sideload Anland or download a rootfs.
An Android permission prompt and Termux's `allow-external-apps=true` setting
must be completed by the device owner. If either is missing, the app reports
that setup could not start.

In Termux, the wizard asks for a Linux username (UID 1000, required by the
current Anland launcher), whether to install optional Firefox, Vim, Dolphin
and Konsole, and confirmation before applying. Firefox is skipped with an
explicit message if the distro only provides a Snap transition package. It
installs repository helpers
and targeted KDE/Wayland packages plus the repository's Plasma Mobile logout
quick setting without `full-upgrade`, and optionally runs
`passwd` interactively. It never stores the password. Re-run with
`bash ~/droidconverge/scripts/install/install-system.sh --update` to fetch a
fast-forward Git update and apply the current repository setup. A checkout
with local changes causes update to stop. Test prerequisites without writes:
`bash ~/droidconverge/scripts/install/install-system.sh --check`.

On the reference tablet, the read-only `--check` preflight passed and the new
Android peripheral list displayed the attached USB keyboard and mice. `--apply`
was intentionally not run against that customized, possibly active chroot.

This is a development installer. Its **fresh-device chroot/Anland prerequisite
stage is guided, not automatic**; those upstream components and their exact
version compatibility must be verified on the target device. The script has
only been syntax/build checked and has not been run on a clean second device.
Do not run `--apply` on the reference tablet while its customized launcher or
KDE session is active. Existing helper backups made by `install-termux.sh` can
be restored from its printed path; a new chroot created for testing can be
removed only after its data has been backed up and reviewed. The wizard never
removes a chroot or changes Android display settings.

This guide describes the current reproducible installation path. It intentionally avoids undocumented manual copies whenever a repository script can perform the same step.

## 1. Clone

```bash
git clone https://github.com/VulcasX/droidconverge.git
cd droidconverge
```

## 2. Verify the Android device

On Windows PowerShell:

```powershell
$adb = "C:\path\to\platform-tools\adb.exe"
& $adb devices
```

The device must appear as `device` rather than `unauthorized` or `offline`.
When USB-C is occupied by a display hub, enable **Wireless debugging** on the
tablet and pair this computer in Android Developer options. On the same Wi-Fi,
use `& $adb mdns services` to find the advertised `_adb-tls-connect._tcp`
endpoint, then `& $adb connect <tablet-ip>:<advertised-port>` and confirm it
appears as `device`. Do not substitute the pairing port for the connect port.
Wireless debugging is session-scoped; reconnect after the tablet changes
network or restarts. Avoid legacy `adb tcpip 5555` for this workflow.

## 3. Build and install the Android Bridge

From the repository root:

```powershell
.\scripts\install\install-android-bridge.ps1 -AdbPath $adb
```

If multiple devices are connected, add `-DeviceSerial` with the serial shown
by `adb devices` (for wireless debugging this is `IP:port`).

The script builds the Android app with the repository Gradle wrapper, checks that the APK exists, and installs it through ADB.

After installation, open DroidConverge Bridge on Android and confirm that the service is running and a token has been generated.

## 4. Install the Termux integration

Copy the repository's Termux helpers into the Termux home/bin layout:

```bash
bash scripts/install/install-termux.sh
```

The script installs:

- `start-ubuntu-kde.sh`
- `startplasma-anland.sh`
- `anland-bridge.sh`
- `anland-haptic-test`
- `droidconverge-session` (optional experimental panel control)
- the Termux launcher shortcut
- the Tasker haptic helper

The installer does not install Anland, Ubuntu or chroot-distro itself; those are external prerequisites.
It backs up any replaced helper under Termux
`~/.local/state/droidconverge/installer-backup-*` and prints that path. It does
not enable Termux external commands or grant Android permissions. Run
`droidconverge-session status` to verify the helper is installed. For the
experimental display panel, follow `docs/EXTERNAL-DISPLAY.md` after the
regular installation. Copy the previous helper back from the printed backup
directory to roll back.
The session helper prefers `$PREFIX/bin/start-ubuntu-kde.sh`; if it is absent,
it can use an executable `~/start-ubuntu-kde.sh` without overwriting that
local launcher. Its stop path requires root to signal the managed Plasma
session and refuses to stop when process identity is ambiguous.

## 5. Install Ubuntu/KDE helpers

Inside the Ubuntu/chroot environment, from a checkout visible to Ubuntu:

```bash
bash scripts/install/install-ubuntu.sh
```

The installer places helpers under `/home/android` by default and mode commands under `~/.local/bin`. Set `DROIDCONVERGE_TARGET_HOME` or `DROIDCONVERGE_LOCAL_BIN` to override these locations.

## 6. Configure the Linux client token

Copy the sanitized example:

```bash
mkdir -p ~/.config
cp configs/droidconverge.json.example ~/.config/droidconverge.json
chmod 600 ~/.config/droidconverge.json
```

Edit the file and insert the Bridge token shown by the Android app.

Never commit the resulting real configuration.

## 7. Start the stack

From Termux:

```bash
start-ubuntu-kde.sh
```

Or use the installed Termux shortcut.

The startup sequence is:

1. start Anland if necessary;
2. wait for `anland/display_daemon.sock`;
3. bind Termux `$PREFIX/tmp` to the Ubuntu chroot `/tmp`;
4. start the Ubuntu KDE entry point;
5. unmount `/tmp` after the session exits.

## 8. Verify haptics

Run the test helper:

```bash
anland-haptic-test
```

For the Linux-to-Android bridge path, use the Bridge CLI or the project-specific haptic integration described in `docs/integrations/LINUX-HAPTICS.md`.

## 9. Troubleshooting

### Bridge port unavailable

Check that the app is running and that no second bridge instance is occupying port `8765`.

### Token rejected

Regenerate the token in the Android app and update the local Linux configuration. Do not copy tokens into Git.

### Anland socket missing

Check that Anland is running and that `$PREFIX/tmp/anland/display_daemon.sock` exists before starting the chroot.

### KDE cannot connect to Wayland

Check the bind mount between Termux `$PREFIX/tmp` and the Ubuntu `/tmp`, then verify `/tmp/anland/display_daemon.sock` from inside Ubuntu.

### Haptic plugin does not react

Verify the Android Bridge first, then the local token/configuration, then the Linux integration library/keyboard build. Treat each layer independently.
# Current app update and profile assets

The optional desktop-app choice now installs Plasma Discover with PackageKit/AppStream and ARM64 graphics diagnostics. It does not add an x86 repository. After setup, run `droidconverge-android-apps sync` as the desktop user to populate Android launchers. The real Bridge token must exist only in the user's private config and must never be copied into the repository.

Steam remains a separate experimental action: run `install-steam-arm64.sh --check`, review a Box64 tag/commit, then set `DROIDCONVERGE_BOX64_REF` and run `--install` inside the chroot. This downloads and builds upstream code locally. Do not run it through the default installer until the reference-device test in `docs/GAMING-AND-ANDROID-APPS.md` passes.

After building `DroidConvergeBridge`, install only the generated APK with `adb install -r`. The KScreen and USB runtime-power helpers are packaged as Android assets and copied into app-private storage at use; they do not need manual installation in Ubuntu. The profile requires the tested NP05J root, existing Ubuntu 26.04 chroot, Anland/KWin, `kscreen-doctor`, and the existing Desktop/Touch helpers. The one-button guided installer remains an **update/setup for an already rooted device with Anland and chroot-distro/Ubuntu present**. It does not yet create a Magisk installation or a clean chroot; do not advertise it as a clean-device installation.

The Termux session helper `scripts/termux/bin/droidconverge-session` should be refreshed on the tablet through the guided installer to expose `STARTING` until Plasma Shell appears. Keep the previous helper copy locally for rollback. Check `status`, managed `start` and `stop` after updating.
