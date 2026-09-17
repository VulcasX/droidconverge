# Scripts

The scripts are grouped by execution environment.

## `scripts/install/`

Installation entry points:

- `install-android-bridge.ps1` — Windows/ADB Android Bridge build and install
- `install-termux.sh` — Termux-side project helper installation
- `install-ubuntu.sh` — Ubuntu/KDE-side helper installation

## `scripts/termux/`

Android/Termux startup, Anland, shortcut and Tasker integration.

## `scripts/ubuntu/`

Ubuntu/KDE mode and startup helpers.

## Safety

The scripts intentionally avoid copying raw personal configuration and do not contain a real Bridge token.
