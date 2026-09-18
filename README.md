# DroidConverge

DroidConverge is an integration project for using Android device capabilities from a Linux/Ubuntu desktop session running on Android. The current release focuses on a local Android Bridge, Termux/Anland startup integration, Ubuntu/KDE startup helpers, and Linux haptic integration.

## Current release scope

This checkpoint intentionally freezes the feature set at the current working state.

The `0.4.0-dev` development branch adds an experimental internal display and
session panel after `0.3.0-dev`. On the RedMagic Astra, wireless ADB verified
an independent Android presentation surface and managed Anland/Plasma
start, stop and restart. KWin started, but `plasmashell`, physical monitor
inspection, keyboard/mouse input and hotplug remain unverified. See
`docs/EXTERNAL-DISPLAY.md` for the test and rollback.
The next development build adds a read-only external input inventory and a
Termux installation wizard. See `docs/INSTALLATION.md` for prerequisites,
update behavior and rollback.
The PC/GitHub/tablet reconciliation and future hardware research boundary are
recorded in `docs/RECONCILIATION-2026-09-18.md`.

Included:

- Android Bridge service on `127.0.0.1:8765`
- token-authenticated newline-delimited JSON protocol
- bridge actions for ping, haptic, vibration, battery, Wi-Fi, Bluetooth and notifications
- Termux startup scripts for Anland and Ubuntu/KDE
- Termux Shortcut and Tasker integration
- Ubuntu/KDE startup and tablet/desktop mode helpers
- DroidConverge haptic integration for Maliit/Plasma Mobile
- reproducible installation and state-collection helpers

Not included yet:

- automatic external-display handling
- Play Store publication workflow
- hardware-specific device support beyond the documented Android/Termux/Ubuntu environment


## Architecture

```text
Linux / Ubuntu / KDE / Plasma Mobile
        |
        | TCP 127.0.0.1:8765 + JSONL + token
        v
DroidConverge Android Bridge
        |
        +-- haptic / vibration
        +-- battery
        +-- Wi-Fi / Bluetooth
        +-- notification
        |
        v
Android framework / rooted system services
```

The Bridge server binds only to loopback. It is not intended to be a network service.

The experimental Anland panel uses `droidconverge-session` in Termux. It
prefers the installed `$PREFIX/bin/start-ubuntu-kde.sh` and falls back to an
executable `~/start-ubuntu-kde.sh`, allowing the reference tablet's local
launcher to remain in place. See `docs/EXTERNAL-DISPLAY.md` for the device
test status and rollback.

## Repository layout

- `DroidConvergeBridge/` — Android application and bridge CLI
- `scripts/termux/` — Termux/Anland startup and helper scripts
- `scripts/ubuntu/` — Ubuntu/KDE startup and mode scripts
- `scripts/install/` — installation entry points
- `integrations/` — Linux-side integration sources
- `configs/` — sanitized example configuration
- `docs/` — setup, architecture, integration and release documentation

## Prerequisites

### Android device

- Android device with USB debugging enabled
- ADB available on the host PC
- for rooted actions: Magisk/root or an equivalent root mechanism
- Termux installed from a trusted source
- Anland/Termux and Ubuntu/chroot-distro installed when using the KDE integration

### PC

- Git
- PowerShell on Windows for the provided Windows installers
- Android SDK/Build Tools appropriate for the Bridge project
- Java/JDK compatible with the Gradle wrapper
- `adb` available to the installer

## Quick start

1. Clone the repository.
2. Build and install the Android Bridge with `scripts/install/install-android-bridge.ps1`.
3. Configure the Bridge token on the Android device.
4. Install the Termux integration with `scripts/install/install-termux.sh`.
5. Install the Ubuntu/KDE helpers with `scripts/install/install-ubuntu.sh`.
6. Create the sanitized Linux-side configuration from `configs/droidconverge.json.example`.
7. Start Anland and Ubuntu/KDE using the Termux shortcut or `start-ubuntu-kde.sh`.
8. Verify the Bridge with the included CLI and haptic test.

Read `docs/INSTALLATION.md` before starting a fresh installation.

## Security

Never commit a real Bridge token, private Android configuration, raw device backups, or personal logs. Only sanitized examples belong in Git.

The Android Bridge listens on loopback, but any local process able to read the token can authenticate to it. Protect the token and local configuration accordingly.

## Disclaimer

DroidConverge is community software. It can require root privileges, modified Android components, custom kernels/drivers, Termux, Anland, chroot containers and locally built Linux components. These changes can affect system stability and device security.

Use the project at your own risk. Test recovery procedures before changing boot, display, graphics, input or privileged services. The project is not affiliated with Android, Google, KDE, Plasma Mobile, Termux, Anland, Magisk or device manufacturers unless explicitly stated.

## Reproducibility policy

The repository is the reproducible source of truth. Device checkpoints are recovery material only. When importing work from a checkpoint:

1. inventory it;
2. compare it with Git;
3. import only project files;
4. exclude personal data, tokens and generated artifacts;
5. verify the installation from a clean checkout;
6. only then tag or publish a release.

## Status

See:

- `docs/PROJECT-STATUS.md`
- `docs/INSTALLATION.md`
- `docs/TERMUX-INTEGRATION.md`
- `docs/integrations/LINUX-HAPTICS.md`
- `docs/RELEASE-PREFLIGHT.md`
- `docs/RELEASE-0.3.0.md`
- `docs/EXTERNAL-DISPLAY.md`
