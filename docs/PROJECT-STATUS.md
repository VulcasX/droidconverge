# Project status

## Unreleased external display work

- Android `DisplayManager` listener, capability paths and internal diagnostic panel implemented on the development branch.
- Unit tests cover all five classification paths; Android build passes.
- RedMagic Astra disconnected baseline: one logical display, 1504x2400, density 360; no active mirror target reported.
- The RedMagic Astra with an AOC 24G4 on USB-C exposed HDMI display ID 2 (1920x1080, presentation capable). Wireless ADB verified a separate app presentation window on ID 2 and its removal by `Solo interno (app)`; the app remained on ID 0.
- Monitor pixels, hotplug, input, Anland/KDE start/stop and Termux command permission remain to be tested. Only the Android secondary presentation surface is device-tested; no extended KDE desktop is declared supported.
- The recovered Maliit TCP patch applies to the matching checkpoint backup, but Linux build and keypress testing are pending.

The safe tablet test and rollback steps are in `docs/EXTERNAL-DISPLAY.md`.

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
8. external display companion: experimental, awaiting connected monitor validation
