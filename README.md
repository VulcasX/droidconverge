# DroidConverge

> **A reproducible bridge between Android and a real GNU/Linux desktop environment.**

DroidConverge is an open-source project for building, documenting, and reproducing a real GNU/Linux desktop environment inside rooted Android devices, with deliberate integration between Android hardware/services and Linux.

The current reference platform is a **RedMagic Astra**, but the project is intentionally device-agnostic. The Astra is a development and validation device, not the project's identity.

## The idea

Android provides the hardware, drivers, power management, connectivity and device services. Linux provides the desktop environment and Linux applications. DroidConverge is the integration layer between the two.

```text
                  ANDROID
                     │
          hardware / services / root
                     │
                     ▼
              DROIDCONVERGE
          Android ↔ Linux integration
                     │
          ┌──────────┴──────────┐
          │                     │
          ▼                     ▼
     Linux chroot          Android Bridge
          │                     │
      Ubuntu + KDE       haptics / battery /
          │              Wi-Fi / Bluetooth /
       Wayland             device services
          │
       Anland
```

## Current reference stack

| Layer | Reference |
|---|---|
| Android | Android 16 |
| Root | Magisk |
| Terminal | Termux GitHub build |
| Linux container | `chroot-distro` real chroot |
| Linux | Ubuntu 26.04.1 LTS ARM64 |
| Desktop | KDE Plasma 6.6.6 |
| Wayland transport | Anland: Termux 5.13.3 |
| KWin | Anland `4:6.6.4-0ubuntu95` |
| Plasma Mobile | `6.6.4-0ubuntu1` |
| GPU | Qualcomm Adreno 830 |
| Graphics | Mesa / Freedreno / Turnip |
| Virtual keyboard | Maliit |
| Privileged Android IPC candidate | Shizuku / Sui |

The reference stack is not a universal compatibility requirement. See `docs/DEVICE-PROFILES.md`.

## What already works

### Real Ubuntu chroot

Ubuntu 26.04.1 LTS ARM64 runs as a real chroot managed with `chroot-distro`, not PRoot.

### KDE Plasma Wayland + Anland

KDE Plasma runs through Wayland using Anland and the matching Anland KWin build. Qualcomm hardware acceleration has been validated on the reference Adreno GPU using Mesa/Turnip.

### Desktop Mode

A user-facing launcher starts **Plasma Desktop** and switches Anland to indirect touchpad-style input:

```text
plasmashell → org.kde.plasma.desktop
touchpad_mode → true
```

The result is that finger movement behaves like a trackpad/cursor controller.

### Touch Mode

A separate launcher starts **Plasma Mobile** and switches Anland to direct touch mapping:

```text
plasmashell → org.kde.plasma.mobileshell
touchpad_mode → false
```

The result is direct finger-to-screen interaction.

The two working user scripts are:

```text
~/.local/bin/plasma-desktop-mode
~/.local/bin/plasma-touch-mode
```

and matching `.desktop` launchers live under:

```text
~/.local/share/applications/
```

These modes are part of the validated reference system and are documented separately in `docs/TOUCH-DESKTOP.md`.

### Plasma Mobile task switcher

The KDE Mobile Task Switcher effect was explicitly enabled and verified working.

### Maliit virtual keyboard

Maliit is integrated with Plasma Mobile and the KDE virtual keyboard integration is enabled. Key-press haptic feedback is enabled at the Maliit level; routing the actual haptic request to Android hardware is the next bridge milestone.

## Android Bridge

The first bridge prototype used a shell daemon and a shared command file. It proved the concept for mode switching and haptic requests, but `/data/local/tmp` is not a suitable long-term IPC mechanism for unprivileged Termux writes because Android security policy/SELinux can block access even when Unix permissions appear permissive.

The project therefore moves toward a native Android Bridge using Android IPC/Binder, with Shizuku/Sui considered where Android's normal application APIs cannot perform privileged actions.

Planned bridge capabilities include:

- haptic feedback
- battery information
- Wi-Fi state and integration
- Bluetooth state and integration
- Android settings shortcuts
- Anland mode control
- future device-specific services

## AI-assisted development / vibe coding

DroidConverge is being developed through an **AI-assisted, iterative "vibe coding" workflow**.

The workflow is intentionally hardware-first:

1. observe and reproduce behavior on the real device;
2. use terminal output and logs as evidence;
3. iterate on scripts, configuration and code with AI assistance;
4. validate the result on hardware;
5. only then promote the result into reproducible project code and documentation.

AI is treated as a development tool, not as proof that something works. Experimental output stays marked as experimental until it has been validated.

This workflow is particularly useful here because the project crosses Android, Linux, root, Wayland, GPU drivers and desktop integration. The public repository records the validated state and the reasoning needed to reproduce it.

## Upstream projects

DroidConverge is an integration project and does not claim ownership of the upstream projects on which it relies.

- **chroot-distro** — https://github.com/Magisk-Modules-Alt-Repo/chroot-distro
- **Anland: Termux** — https://github.com/lfdevs/anland-termux
- **Termux** — https://github.com/termux/termux-app
- **Termux:API** — https://github.com/termux/termux-api
- **Shizuku** — https://github.com/RikkaApps/Shizuku
- **Shizuku API** — https://github.com/RikkaApps/Shizuku-API
- **KDE Plasma** — https://invent.kde.org/plasma
- **Maliit** — https://gitlab.com/maliit
- **Mesa** — https://gitlab.freedesktop.org/mesa/mesa
- **Ubuntu** — https://ubuntu.com/

See `SOURCES.md` and `THIRD-PARTY-NOTICES.md` for attribution and source details.

## Current status

**Working reference platform / early integration phase.**

Validated:

- real Ubuntu 26.04.1 ARM64 chroot
- KDE Plasma Wayland
- Anland 5.13.3
- KWin Anland 6.6.4 Ubuntu build
- Adreno 830 hardware acceleration
- Plasma Desktop mode
- Plasma Touch/Mobile mode
- Anland direct ↔ touchpad input switching
- Plasma Mobile task switcher
- Maliit virtual keyboard
- Android vibration through the working Termux:API execution path

In progress:

- Android-native Bridge
- Maliit → Android haptics
- battery / Wi-Fi / Bluetooth integration
- one-tap startup launcher
- reproducible installation/recovery guide
- device profiles

Deferred until the core integration is stable:

- external display support
- broader launcher/interface work

## Donations

DroidConverge is an independent open-source project. Donations may support device testing, additional hardware, development time, infrastructure and documentation.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/I6E026ZKM0)

## License

Original project code and scripts: **GNU GPL v3 or later**.

Original project documentation: **CC BY-SA 4.0**.

Third-party projects retain their own licenses and copyright.

See `LICENSE`, `LICENSE-DOCS.md`, and `THIRD-PARTY-NOTICES.md`.

## Contributing

See `CONTRIBUTING.md`. Hardware testing, device profiles, reproducibility fixes, documentation and Android Bridge development are especially useful contributions.
