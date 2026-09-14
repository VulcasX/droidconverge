# Installation guide

This document is the canonical reproducible guide. It will be filled from the live validated device snapshot rather than from memory.

## Required baseline for the reference device

- unlocked bootloader
- Magisk/root
- Android 16
- ARM64
- Termux GitHub build
- chroot-distro

## Installation flow

```text
Android / root
      ↓
Termux
      ↓
chroot-distro
      ↓
Ubuntu 26.04.1 ARM64
      ↓
KDE Plasma
      ↓
Anland 5.13.3
      ↓
KWin Anland 6.6.4 build
      ↓
Mesa/Turnip
      ↓
Maliit
      ↓
Desktop / Touch modes
```

The exact commands, URLs, versions, checksums, package holds and recovery steps will be promoted here after the reference device state is collected and reviewed.
