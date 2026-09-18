# Project status

## 0.5.0-dev development

- The owner observed Anland on the external monitor only after choosing
  RedMagic's Schermo esteso option. Read-only ADB still shows a separate HDMI
  display and attached keyboard/mouse. Anland's actual monitor pixels and
  input routing have not yet been independently verified by this build.
- The app now enumerates external Android input devices and opens input-method or
  Bluetooth settings. It does not reroute inputs or alter display settings.
- The panel opens Anland and Android display settings for the observed manual
  RedMagic route; the monitor status window explicitly describes its scope.
- A new managed session reached Anland/Plasma/KWin, and Android brought Anland
  to the HDMI display. A temporary HDMI framebuffer capture showed the KDE
  desktop. The app now requests that display through the public launch API;
  physical monitor and USB input tests still need owner confirmation.
- An interactive Termux installer and fast-forward updater are implemented.
  The `--check` preflight passed on the reference tablet, and the 0.5.0-dev
  clean Android build/tests passed. The app was installed and UI accessibility
  showed the attached USB keyboard and mice. Full fresh-device install is pending
  on a sacrificial or backed-up target with compatible upstream components.
- The latest `main` audio lifecycle and Plasma Mobile logout work was merged
  into this branch. The guided installer now includes the logout setting in
  future helper updates; fresh-device testing is pending.


## Unreleased external display work

- Android `DisplayManager` listener, capability paths and internal diagnostic panel implemented on the development branch.
- Unit tests cover all five classification paths; Android build passes.
- RedMagic Astra disconnected baseline: one logical display, 1504x2400, density 360; no active mirror target reported.
- The RedMagic Astra with an AOC 24G4 on USB-C exposed HDMI display ID 2 (1920x1080, presentation capable). Wireless ADB verified a separate app presentation window on ID 2 and its removal by `Solo interno (app)`; the app remained on ID 0.
- HDMI framebuffer capture showed the companion text. With the Termux helper installed and permission granted, the panel returned `UNKNOWN` for a pre-existing unmanaged Anland session, which was left running.
- Physical monitor inspection, hotplug and input remain untested. The Android secondary presentation surface is device-tested; no extended KDE desktop is declared supported.
- Shutdown diagnosis: terminating KWin alone caused its wrapper to restart it; terminating the existing `plasma_session` closed KDE/KWin, but Anland and its socket remained. Wireless ADB then went offline before the remaining session could be checked or a managed lifecycle test could start. No new session was launched.
- After reconnecting ADB wirelessly, the remaining orphan Anland process was stopped with TERM. The panel then reported `STOPPED`. Its first start attempt failed safely because the tablet's active `start-ubuntu-kde.sh` lives in Termux home rather than `$PREFIX/bin`; the home launcher fallback was subsequently tested.
- The fallback was exercised: the managed launcher, Anland, `plasma_session` and KWin ran; `plasmashell` was not observed. The initial stop only killed the launcher and left KDE/Anland. These were closed manually, and the revised helper checks process identity before terminating Plasma and its own Anland child.
- Revised start/stop/restart passed on RedMagic: after managed start, `RUNNING` was reported; restart produced new Anland and Plasma process IDs; final stop removed Anland, Plasma, KWin and the socket, and helper status became `STOPPED`. Pending state and delayed UI refresh were installed and device-tested. `plasmashell` was not observed.
- The recovered Maliit TCP patch applies to the matching checkpoint backup, but Linux build and keypress testing are pending.

The safe tablet test and rollback steps are in `docs/EXTERNAL-DISPLAY.md`.

## Validated platform

- Android 16
- Magisk root
- Termux GitHub build
- real chroot via chroot-distro
- Ubuntu 26.04.1 LTS ARM64
- KDE Plasma 6.6.x with the validated Anland KWin stack
- Anland: Termux 5.13.3
- KWin Anland `4:6.6.4-0ubuntu95`
- Plasma Mobile integration
- Qualcomm Adreno 830
- Mesa/Freedreno/Turnip/KGSL hardware acceleration
- Desktop/Touch mode switching
- Plasma Mobile task switcher
- Maliit virtual keyboard

## Validated DroidConverge integration

- Android Bridge service on loopback (`127.0.0.1:8765`)
- token-authenticated newline-delimited JSON protocol
- bridge ping
- Android haptic and vibration actions
- battery information
- Wi-Fi integration
- Bluetooth integration
- Android notification integration
- Termux Shortcut and Tasker startup integration
- Ubuntu/KDE startup helpers
- tablet/desktop mode helpers
- Linux-side haptic integration for Maliit/Plasma Mobile
- restart-safe Anland PipeWire/WirePlumber/pipewire-pulse lifecycle
- Anland remote speaker and microphone exposure to the Linux session
- Firefox video/audio playback after clean Anland audio-session startup

## Validated audio lifecycle fix

Repeated KDE/Anland starts previously could leave stale PipeWire services and multiple WirePlumber processes using the same runtime. This could make `wpctl` and `pactl` hang and could stall Firefox/YouTube playback even though media decoding and GPU acceleration were functional.

The current `scripts/ubuntu/start-anland-plasma.sh` performs runtime-scoped cleanup, removes stale sockets and locks, starts one PipeWire/WirePlumber/pipewire-pulse stack, performs health checks, and cleans up when the Plasma session exits.

The validated reference session has exactly one PipeWire, one WirePlumber and one pipewire-pulse process. `wpctl`, `pactl`, Anland speaker/microphone, Firefox YouTube video/audio and Firefox `about:support` were verified after a normal DroidConverge restart.

See `docs/TROUBLESHOOTING-AUDIO.md` for diagnostics and recovery details.

## Legacy / prototype

The original shell bridge and command-file transport are legacy/prototype components. Unprivileged Termux access to `/data/local/tmp` is not used as the stable IPC foundation of the current Android Bridge.

## Next

1. continue Android launcher/startup integration and make the normal DroidConverge launch path cleaner
2. continue KDE/Ubuntu optimization and useful desktop application integration
3. refine tablet-friendly Plasma interface and mode switching
4. continue Firefox/browser and graphics integration hardening
5. expand Android/Linux integration for storage, clipboard and input
6. improve window management, resolution and startup automation
7. add broader device profiles and portability work
8. external-display automation last
