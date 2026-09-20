# 0.5.1-dev

- Add the first localized Android UI surface with English as the source/fallback language and Italian, French, Spanish and Portuguese translations for the primary navigation and controls.

# 0.5.0-dev development
- Incorporate the web-side ARM64 graphics recap: mount a private 512 MiB `/dev/shm` tmpfs idempotently for each managed KDE session and restore it on exit.
- Record the verified Chrome ARM64 Wayland baseline (Freedreno/Turnip, accelerated compositing and working YouTube). Keep Firefox diagnosis separate.
- Retire the Box64/Steam installer after the project decision to prefer native ARM64 Linux applications and Android GameHub for x86/Windows gaming.
- Validate the three RedMagic scale profiles on the live HDMI session and correct KGSL utilization for NP05J's reset-on-read `gpubusy` node.
- Validate 64 generated Android application launchers, Android app startup from KDE, and Wi-Fi/Bluetooth status through the authenticated Bridge.
- Record the completed Box64/Steam experiment and its synchronization failures before removing that unsupported installation path.
- Probe Qualcomm video decode: FFmpeg reaches `msm_vidc_decoder` but cannot allocate output buffers. No hardware decode support is claimed and temporary DMA-heap modes were restored.
- Split scaling into Tablet Touch, Tablet Desktop and external Monitor Desktop profiles, each with an independent value.
- Add a token-authenticated Android launcher catalog and KDE menu generator, plus Linux CLI access to Android-owned Wi-Fi/Bluetooth controls and settings.
- Add read-only KGSL whole-device GPU utilization, clearly separated from unavailable per-chroot attribution.
- Add an ARM64 Discover/PackageKit setup and graphics/video capability probe.
- Correct the MagicDesk reference license to GPLv3 and record that no source, dependency, submodule or runtime component is used.

- Add read-only CPU/GPU, skin and battery temperatures plus internal fan presence/state in the Sessione panel, only when the kernel exposes matching sensors. These are whole-device readings, not chroot attribution.

- Show the Android monitor's active resolution/refresh rate and up to eight detected modes in the display panel. Selecting an Android mode remains in the device's own settings; KScreen controls only the Anland virtual output scale.

- Rework the Android panel into Sessione, Schermo e I/O, Installa and Avanzate tabs with a shared app/README logo and live chroot CPU/RAM estimates. GPU remains unavailable until a trustworthy counter is identified.
- Distinguish KDE startup from a ready Plasma Shell, and reapply the RedMagic KScreen Desktop/Touch scale profile when a new KWin session starts. Monitor and tablet values default to 100% and 170%, with explicit manual values and rollback.
- Keep a routed USB keyboard or mouse awake using its temporary `power/control` setting; save and restore the prior value on route removal. Mouse and keyboard state transitions were verified on the RedMagic Astra.

- Simplify the Android home panel: session state and launch controls first;
  display/peripheral diagnostics and API/haptic tests are collapsible.
- Show read-only Termux, Anland and Ubuntu/KDE process evidence beside the
  managed session result. Distinguish an orphaned KDE process from a stopped
  session, and add a guarded `Ripara` action for that exact state.
- Diagnose RedMagic's `Blocked by AutoLaunch` response separately from a
  missing RUN_COMMAND permission and offer a direct Termux launch.

- Report removable USB volume state and Wi-Fi/Bluetooth adapter state in the
  peripheral panel. The reference exFAT stick is currently `unmountable`, so
  no chroot mount or cooler control is exposed; validation and rollback steps
  are documented for the hub.

- Show connected external Android input devices in the internal panel and
  provide a shortcut to Android settings. RedMagic extended-screen routing of
  Anland remains a manual vendor action.
- Add direct Anland/display-settings entry points and clarify that the monitor
  status window is an app presentation, not KDE output.
- Validate KDE pixels in the HDMI framebuffer after managed start and launch
  Anland on that display through Android's public activity options.
- Add an explicit Anland-to-tablet action beside HDMI placement for display
  rollback without changing persistent Android display settings.
- Record owner confirmation of KDE on the physical monitor. Add USB/audio
  inventory and independent root-backed Android input routing per physical
  keyboard/mouse, with an explicit tablet return action. Android's input
  association and rollback were verified on RedMagic; physical KDE events and
  audio playback still need owner verification.
- Add a half-second opt-in HDMI audio tone from the Android app to distinguish
  Android output routing from the still unverified KDE/PipeWire sound path.
- Add a Termux interactive installer for repository helpers, Ubuntu account
  and targeted desktop packages, with an optional desktop-app choice and
  fast-forward repository update. It checks pre-existing root, Anland and
  Ubuntu chroot before writes; clean-device end-to-end validation is pending.
- Incorporate the newer `main` Anland audio lifecycle and Plasma Mobile logout
  integration; the guided installer includes the logout helper on updates.

## 0.3.0-dev - 2026-09-15

- Consolidated the Android Bridge TCP service and authentication model.
- Recovered and packaged the Termux/Ubuntu startup integration from the tablet checkpoint.
- Preserved selected Maliit/Plasma Mobile integration sources for further work.
- Added Android, Termux and Ubuntu installation helpers.
- Added release/security documentation and sanitized configuration example.
# Changelog

## 0.4.0-dev - 2026-09-17

- Added five capability paths and an experimental Android display/session panel. On RedMagic Astra, a USB-C HDMI display exposed a separate presentation surface; its companion content and in-app rollback were verified over wireless ADB.
- Added opt-in Termux `RUN_COMMAND` session control with a fallback for an existing executable `~/start-ubuntu-kde.sh`. Managed start, stop and restart were tested on RedMagic; process identity checks prevent stopping an unrelated Anland session.
- Fixed an incomplete stop that left KDE and Anland running, and fixed stale panel results during asynchronous Termux commands.
- Removed nullable `JSONObject.optString` type warnings from the Bridge parser without changing the optional-field contract.
- Aligned the Ping response and app label with the Gradle version after a tablet Ping test found a stale `0.3.0-dev` response.
- Added an explicit ADB serial option to the Android installer and wireless ADB instructions for USB-C display testing.
- Recovered a selective Maliit TCP haptic patch from the tablet checkpoint and verified that it applies to the matching source. Linux build and runtime validation remain pending.
- Removed duplicate Termux/Ubuntu script copies and the obsolete installer; documented canonical install paths and rollback.
- KDE `plasmashell`, physical monitor inspection, hotplug and keyboard/mouse input remain unverified. No extended KDE desktop support is claimed.


- public project bootstrap
- device-agnostic project identity
- comprehensive landing README
- Touch/Desktop mode documentation
- Android Bridge architecture
- AI-assisted/vibe-coding workflow documented
- upstream attribution structure
