# Project status

## Validated

- Android 16
- Magisk root
- Termux GitHub build
- real chroot via chroot-distro
- Ubuntu 26.04.1 LTS ARM64
- KDE Plasma 6.6.6
- Anland: Termux 5.13.3
- KWin Anland `4:6.6.4-0ubuntu95`
- Plasma Mobile `6.6.4-0ubuntu1`
- Qualcomm Adreno 830
- Mesa/Turnip hardware acceleration
- Desktop/Touch mode switching
- Plasma Mobile task switcher
- Maliit virtual keyboard
- Android haptic through Termux:API in the validated context

## Prototype

The existing shell bridge handled `touch`, `desktop`, and `haptic`. Its command-file transport is considered legacy/prototype because unprivileged Termux access to `/data/local/tmp` is not a good stable IPC foundation.

## Next

1. Android Studio/Kotlin Bridge
2. haptic provider
3. battery API
4. Wi-Fi/Bluetooth integration
5. Anland mode control through the new bridge
6. startup launcher
7. broader device profiles
8. external displays last
