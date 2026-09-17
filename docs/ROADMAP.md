# Roadmap

## Current external display validation gate

- [x] Record RedMagic disconnected display baseline with read-only ADB.
- [x] Add public-API display classification and a conservative internal panel.
- [x] Connect the USB-C hub and AOC monitor; capture sanitized before/after display count and mirror status over wireless ADB.
- [x] Verify the optional Android presentation on display 2 and its in-app rollback.
- [x] Capture the HDMI display's companion content; install the Termux helper and verify `status` reports an unmanaged active session as `UNKNOWN`.
- [ ] Verify physical monitor pixels, hotplug, orientation and input on RedMagic Astra.
- [ ] After the existing Anland session ends, verify start/status/stop/restart with a newly managed session and rollback.
- [ ] Recover the tablet's wireless ADB endpoint after it went offline; confirm the old Anland listener is gone before starting a managed session.
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
