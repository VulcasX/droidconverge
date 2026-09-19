# Project status

## Session recovery and panel — 2026-09-18

The apparent RUN_COMMAND permission failure was reproduced on RedMagic with
the actual Android response `Blocked by AutoLaunch`. The Android permission
was granted and Termux already allowed external apps. Opening Termux normally
let the Bridge request status. A live KDE `plasma_session` still had the
Ubuntu chroot as its process root, while Anland was absent and its old socket
remained; the old helper returned `UNKNOWN` and refused a second start.

The panel now separates the last managed command response from read-only
Termux/Anland/KDE process evidence, puts primary controls first and collapses
diagnostic settings. The revised helper classified this state as `ORPHANED`.
Git attributes keep the executable Termux helper's line endings compatible
with its Android bash shebang when checked out on Windows.
Its guarded `recover` action sent TERM to the verified KDE process, removed
the inactive Anland socket and returned `RECOVERED`. A subsequent app `Avvia`
returned `STARTED`; all three expected processes were observed. The session
was left running. Physical monitor, input and audio checks remain separate.

## Wireless ADB / hub check — 2026-09-18

The RedMagic Astra was reached at a fresh wireless-debugging port while its
USB-C hub, HDMI monitor, keyboard, mouse and flash drive were attached. The
current debug APK installed and its activity remained running. Android reports
the flash drive as an exFAT public volume in `unmountable` state; the kernel
lists exFAT support. No filesystem repair, format or chroot mount was attempted.
The peripheral panel now reports removable-volume state plus Wi-Fi and
Bluetooth adapter state. An enabled Bluetooth adapter does not prove that the
Cooler 6 Pro is connected or controllable. Its protocol and fan semantics remain
unverified. The APK build and unit tests passed; physical KDE input/audio and
fresh-device installation remain pending.

## 0.5.0-dev development

- On 2026-09-19 the current APK and live helpers were tested on RedMagic Astra over wireless ADB with KDE on HDMI. KGSL reported tablet-wide GPU activity in both the app and Ubuntu; the reset-on-read calculation was corrected. All three scale profiles applied and the display was left at Monitor Desktop 100%.
- The authenticated Android catalog generated 64 KDE launchers and an Android app launched successfully from Ubuntu. Android-owned Wi-Fi and Bluetooth status both worked. This is control through the Bridge, not raw device passthrough.
- Plasma Discover is present and APT remains ARM64-only. Qualcomm H.264 decoding reached `msm_vidc_decoder` but failed output-buffer allocation; VA-API also lacks a usable driver. Temporary DMA-heap permission changes were restored, and hardware decoding remains unsupported.
- Official Box64/Box32 tag `v0.4.5-1` built on-device. Steam installed, appeared in the KDE menu and started through an explicit Box64 Bash launcher because Android's `binfmt_misc` is empty. The client stayed alive but emitted synchronization assertions; login and game launch remain unverified.

- The owner observed Anland on the external monitor only after choosing
  RedMagic's Schermo esteso option. Read-only ADB still shows a separate HDMI
  display and attached keyboard/mouse. The owner confirmed KDE pixels on that
  monitor; this build verified Android input association, with KDE input events
  still awaiting the owner's direct check.
- The app now enumerates external Android input devices and independently
  routes selected physical keyboards/mice to HDMI via a root app_process
  helper. Per-device return to the tablet was verified in Android diagnostics.
  It does not alter persistent display settings or mount USB storage.
- The panel opens Anland and Android display settings for the observed manual
  RedMagic route and can move Anland back to the tablet. Both task-placement
  directions were verified; the monitor status window describes its scope.
- A new managed session reached Anland/Plasma/KWin, and Android brought Anland
  to the HDMI display. A temporary HDMI framebuffer capture showed the KDE
  desktop. The app now requests that display through the public launch API;
  the owner confirmed KDE on the physical monitor. Keyboard/mouse do not yet
  operate KDE reliably. The app inventories USB/audio and offers a short HDMI
  tone. The KDE chroot's `anland-speaker` sink accepted a local WAV via `paplay`;
  audible HDMI playback and physical KDE input still need owner confirmation.
- An interactive Termux installer and fast-forward updater are implemented.
  The `--check` preflight passed on the reference tablet, and the 0.5.0-dev
  clean Android build/tests passed. The app was installed and UI accessibility
  showed the attached USB keyboard and mice. Full fresh-device install is pending
  on a sacrificial or backed-up target with compatible upstream components.
- The latest `main` audio lifecycle and Plasma Mobile logout work was merged
  into this branch. The guided installer now includes the logout setting in
  future helper updates; fresh-device testing is pending.
- The standalone input controls, HDMI audio probe and two-way Anland placement
  were installed and exercised on the RedMagic. A final local safety edit to
  restore input after a failed root command passed build/tests and was installed
  on the reconnected tablet. Route/return after this edit still requires a
  physical input smoke test with KDE visible.


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

### RedMagic session and peripherals, 2026-09-18

Read-only thermal telemetry was checked on NP05J: the app displayed CPU 58.7°C, GPU 50.8°C, skin 38.9°C, battery 37.7°C and internal fan active at level 4 during one sample. These are shared device sensors, not CPU/GPU usage attributable to Ubuntu. The fan is detected but has no write controls; external Cooler 6 Pro control still requires a verified connection and protocol.

KDE's Mouse settings error was investigated without changing mounts: its KCM library exists, but the Ubuntu chroot currently has no `/dev/input` directory. Android owns the routed physical HID devices; KWin/Anland can receive pointer events while KDE's libinput settings has no physical devices to enumerate. Blindly bind-mounting Android `/dev/input` could duplicate events and is not enabled. The kernel LED list has lock-key nodes but no identifiable keyboard-backlight node, so backlight control is still unsupported.

The display panel now lists Android's active HDMI resolution/refresh and available modes from public APIs. On the connected RedMagic monitor it reported 1920×1080 at 180 Hz, with 640×480 at 60 Hz also advertised. This is a read-only probe; mode selection remains in Android settings and has not been tested with a physical mode change.

The rebuilt Android app was installed with `adb install -r`. Its four-tab panel, CPU/RAM chroot readings and 170% tablet / 100% HDMI fields were inspected on device. KScreen reported one virtual Anland output at 1920x1080; applying 170%, then 100% Desktop, and rollback were verified through `kscreen-doctor`. Automatic physical hotplug, panel temperature and GPU counters are still pending.

The MOSART mouse changed USB runtime `power/control` from `auto` to `on` when routed to HDMI and back to `auto` when returned to the tablet. The SONiX keyboard changed to `on` when routed to HDMI. These are temporary per-device settings, with the original value saved in app-private preferences. Actual idle/wake behavior over a longer session still needs observation. The hub currently exposes no Android public removable volume, so no stick was mounted in Ubuntu.

The diagnostic scripts are read-only. Only the named device's runtime USB power control and the KScreen virtual-output scale are modified; no Android `wm` or density setting is changed. See `docs/EXTERNAL-DISPLAY.md` for checks and rollback.

Updating the Termux session helper directly through ADB failed with `Permission denied` on Termux's private bin path, even with Magisk root. The active helper was unchanged, and its `.prev` copy remains available on the tablet. Its new `STARTING` report therefore still needs installation from within Termux and a device test.

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

Current unverified work adds three scale profiles, a Bridge-backed Android application menu, Android radio controls from Ubuntu, ARM64 Discover setup, graphics capability diagnostics and an opt-in Box64 Steam installer. Local Android build/unit tests pass; device installation is pending because wireless ADB at `192.168.1.22:35135` refused the connection on 2026-09-19. None of these pending paths is marked device-tested.

1. continue Android launcher/startup integration and make the normal DroidConverge launch path cleaner
2. continue KDE/Ubuntu optimization and useful desktop application integration
3. refine tablet-friendly Plasma interface and mode switching
4. continue Firefox/browser and graphics integration hardening
5. expand Android/Linux integration for storage, clipboard and input
6. improve window management, resolution and startup automation
7. add broader device profiles and portability work
8. external-display automation last
