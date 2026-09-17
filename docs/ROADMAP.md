# Roadmap

## Current external display validation gate

- [x] Record RedMagic disconnected display baseline with read-only ADB.
- [x] Add public-API display classification and a conservative internal panel.
- [ ] Connect the known-working USB-C adapter and monitor; capture sanitized before/after display count and mirror status.
- [ ] Verify hotplug, optional presentation, orientation and input on RedMagic Astra.
- [ ] Install and opt in to Termux command control; verify start/status/stop/restart with a newly managed session and rollback.
- [ ] Mark RedMagic mirror or secondary path tested only after those checks. Samsung, Motorola and Pixel remain experimental.

Commands, expected results and rollback are in `docs/EXTERNAL-DISPLAY.md`.

## Phase 0 — preserve the known-good system

- [x] Real Ubuntu chroot
- [x] KDE Plasma Wayland
- [x] Anland
- [x] Hardware acceleration
- [x] Plasma Desktop mode
- [x] Plasma Touch/Mobile mode
- [x] Task switcher
- [x] Maliit keyboard
- [ ] Device snapshot
- [ ] Final reproducible installation guide

## Phase 1 — Android Bridge

- [ ] Android Studio/Kotlin project
- [ ] haptic IPC
- [ ] battery
- [ ] Wi-Fi state
- [ ] Bluetooth state
- [ ] Android settings intents
- [ ] Anland control
- [ ] Shizuku/Sui privileged layer

## Phase 2 — integration

- [ ] Maliit haptic keypress
- [ ] battery integration
- [ ] Wi-Fi integration
- [ ] Bluetooth integration
- [ ] reliable startup

## Phase 3 — user experience

- [ ] Android launcher
- [ ] one-tap Ubuntu + Anland startup
- [ ] mode selection
- [ ] recovery UI

## Phase 4 — portability

- [ ] device profile format
- [ ] additional Snapdragon devices
- [ ] non-reference hardware documentation

## Phase 5 — hardware expansion

- [ ] external display companion: implementation started; device validation pending
- [ ] additional peripherals
- [ ] performance profiles
