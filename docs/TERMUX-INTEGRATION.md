# DroidConverge â€” Termux / Anland integration

This repository contains project-owned helper scripts for the Android/Termux + Anland + Ubuntu/KDE integration used during development.

## Security

Never commit the real DroidConverge haptic token, personal Android/Termux configuration, signing keys, raw checkpoint archives, or private certificates. Use `configs/droidconverge.json.example` as the public template.

## Installation

Run `scripts/termux/install-droidconverge-termux.sh` from inside Termux after reviewing the device-specific paths in the recovered startup scripts.

Some scripts assume the existing `ubuntu26` chroot, the Anland Termux package, root access, and the device paths used by the development setup.
