# Roadmap

## 0.5.0-dev validation

- [x] Separate managed command result from live process evidence in the app;
      collapse advanced diagnostics and API tests.
- [x] Diagnose RedMagic AutoLaunch rejection and verify opening Termux restores
      the RUN_COMMAND path.
- [x] Detect a verified orphan KDE process in the reference chroot, recover it
      explicitly from the app, then verify a managed start.
- [ ] Verify the RedMagic Termux AutoLaunch setting across a cold app launch;
      retain the in-app Termux shortcut when OEM policy blocks the service.

- [x] Identify RedMagic's manual Schermo esteso route from owner observation.
- [x] Detect external USB input devices through Android's public InputManager.
- [x] Launch Anland on the detected Android HDMI display and expose display settings.
- [x] Add a Termux installer with preflight, account and optional app choices.
- [x] Verify KDE pixels in an Android HDMI framebuffer capture.
- [x] Owner confirmed KDE picture on the physical monitor.
- [x] Implement and verify RedMagic input association and explicit tablet
      restoration per external keyboard/mouse through DroidConverge alone.
- [ ] Route physical keyboard/mouse to Anland and verify events in KDE.
- [ ] Verify HDMI audio playback and diagnose intermittent keyboard wake input.
- [ ] Verify crash/disconnect recovery and the first-key-after-idle behavior.
- [ ] Add a separate USB storage permission and mount/unmount flow for the chroot.
- [x] Show Android removable-volume state and Wi-Fi/Bluetooth adapter state
      in the peripheral panel, without claiming accessory control.
- [ ] Diagnose the reference exFAT volume reported `unmountable`; only offer
      chroot mounting after Android mounts a healthy volume, with rollback.
- [ ] Research an owned Android surface/Wayland transport as a future
      replacement for Anland; retain the working Anland backend until an
      independently tested video, input, audio and rollback path exists.
- [ ] Test the installer from a clean second device with compatible Anland and
      Ubuntu 26.04 chroot; record package versions and rollback.
- [ ] Validate a subsequent fast-forward update on that device.
- [ ] Research licensed NP05J fan/charging/RGB implementations separately,
      then build a shared token-owning Linux platform service with read-only
      capability and fan diagnostics before adding hardware writes.
- [ ] Verify Cooler 6 Pro connection/protocol and licensed reference sources;
      test read-only capability detection before offering cooler controls.


## Current external display validation gate

- [x] Record RedMagic disconnected display baseline with read-only ADB.
- [x] Add public-API display classification and a conservative internal panel.
- [x] Connect the USB-C hub and AOC monitor; capture sanitized before/after display count and mirror status over wireless ADB.
- [x] Verify the optional Android presentation on display 2 and its in-app rollback.
- [x] Capture the HDMI display's companion content; install the Termux helper and verify `status` reports an unmanaged active session as `UNKNOWN`.
- [x] Owner verified physical KDE picture on RedMagic Astra.
- [ ] Verify hotplug, orientation, pointer, keyboard and audio on RedMagic Astra.
- [x] After the existing Anland session ends, verify start/status/stop/restart with a newly managed session and rollback.
- [x] Recover wireless ADB at the new port, stop the orphan Anland daemon and confirm `STOPPED` from the panel.
- [x] Verify the home-launcher fallback against the tablet's existing customized `~/start-ubuntu-kde.sh` without overwriting it.
- [x] Install and verify the revised safe stop logic against a new managed session.
- [x] Verify pending/result refresh in the Android panel.
- [x] Recheck `plasmashell` after managed start and capture KDE pixels on HDMI.
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

- [x] Four-tab Android UI, project icon, chroot CPU/RAM estimates and explicit GPU-unavailable state.
- [x] Manual KScreen tablet/HDMI scaling and Desktop/Touch switch on the RedMagic reference session.
- [x] Per-routed-device temporary USB wake setting and rollback, tested for MOSART mouse and SONiX keyboard.
- [ ] Physically unplug/replug HDMI to verify automatic profile switching and mode recovery.
- [ ] Observe keyboard/mouse after a long idle interval; test keyboard LED/backlight separately.
- [ ] Identify mounted removable Android volume before exposing a safe chroot mount; do not format or raw-mount the current stick.
- [ ] Confirm KDE HDMI audio on the physical monitor and investigate KDE input KCM's missing libinput device list.
- [ ] Validate root fan interface on NP05J and Cooler 6 Pro Bluetooth protocol before exposing write controls.
- [ ] Compare Firefox and another ARM64 browser using repeatable GPU/video probes. Steam on ARM64 requires a separately tested compatibility path.
- [ ] Finish and test the full clean-device installer; current wizard requires existing Magisk root, Anland and Ubuntu chroot.

- [ ] external display companion: implementation started; device validation pending
- [ ] additional peripherals
- [ ] performance profiles
