# Roadmap

## 0.5.0-dev validation

- [x] Identify RedMagic's manual Schermo esteso route from owner observation.
- [x] Detect external USB input devices through Android's public InputManager.
- [x] Add a Termux installer with preflight, account and optional app choices.
- [ ] Verify the actual KDE picture and keyboard/mouse routing on the monitor.
- [ ] Test the installer from a clean second device with compatible Anland and
      Ubuntu 26.04 chroot; record package versions and rollback.
- [ ] Validate a subsequent fast-forward update on that device.
- [ ] Research licensed NP05J fan/charging/RGB implementations separately,
      then build a shared token-owning Linux platform service with read-only
      capability and fan diagnostics before adding hardware writes.


## Current external display validation gate

- [x] Record RedMagic disconnected display baseline with read-only ADB.
- [x] Add public-API display classification and a conservative internal panel.
- [x] Connect the USB-C hub and AOC monitor; capture sanitized before/after display count and mirror status over wireless ADB.
- [x] Verify the optional Android presentation on display 2 and its in-app rollback.
- [x] Capture the HDMI display's companion content; install the Termux helper and verify `status` reports an unmanaged active session as `UNKNOWN`.
- [ ] Verify physical monitor pixels, hotplug, orientation and input on RedMagic Astra.
- [x] After the existing Anland session ends, verify start/status/stop/restart with a newly managed session and rollback.
- [x] Recover wireless ADB at the new port, stop the orphan Anland daemon and confirm `STOPPED` from the panel.
- [x] Verify the home-launcher fallback against the tablet's existing customized `~/start-ubuntu-kde.sh` without overwriting it.
- [x] Install and verify the revised safe stop logic against a new managed session.
- [x] Verify pending/result refresh in the Android panel.
- [ ] Investigate the missing `plasmashell` process and verify the desktop picture on the monitor.
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
