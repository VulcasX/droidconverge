# Project status

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
