# Project status

## Unreleased external display work

- Android `DisplayManager` listener, capability paths and internal diagnostic panel implemented on the development branch.
- Unit tests cover all five classification paths; Android build passes.
- RedMagic Astra disconnected baseline: one logical display, 1504x2400, density 360; no active mirror target reported.
- The RedMagic Astra with an AOC 24G4 on USB-C exposed HDMI display ID 2 (1920x1080, presentation capable). Wireless ADB verified a separate app presentation window on ID 2 and its removal by `Solo interno (app)`; the app remained on ID 0.
- HDMI framebuffer capture showed the companion text. With the Termux helper installed and permission granted, the panel returned `UNKNOWN` for a pre-existing unmanaged Anland session, which was left running.
- Physical monitor inspection, hotplug, input and managed Anland/KDE start/stop remain untested. Only the Android secondary presentation surface is device-tested; no extended KDE desktop is declared supported.
- Shutdown diagnosis: terminating KWin alone caused its wrapper to restart it; terminating the existing `plasma_session` closed KDE/KWin, but Anland and its socket remained. Wireless ADB then went offline before the remaining session could be checked or a managed lifecycle test could start. No new session was launched.
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
