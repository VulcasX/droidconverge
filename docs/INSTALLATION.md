# DroidConverge installation

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

## 3. Build and install the Android Bridge

From the repository root:

```powershell
.\scripts\install\install-android-bridge.ps1 -AdbPath $adb
```

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
