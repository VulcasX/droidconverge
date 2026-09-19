# Device profiles

RedMagic Astra NP05J session observation (2026-09-18): this firmware blocked
a cold Bridge-to-Termux service start with `Blocked by AutoLaunch` despite
RUN_COMMAND permission and Termux's external-app setting being enabled. A
normal Termux launch restored the command path. A KDE process with the Ubuntu
chroot root but no Anland process was classified as `ORPHANED`, recovered and
started again through the app. Other devices need their own policy checks.

RedMagic Astra NP05J hub check (2026-09-18): Android sees keyboard, mouse and
the exFAT USB stick, but marks the stick `unmountable`; no Ubuntu mount was
tested. Wi-Fi/Bluetooth radio status is shown in the app. Cooler 6 Pro
connection and control, HDMI audio audibility and physical KDE input delivery
remain unverified. This observation does not generalize to other devices.

The project is device-agnostic by design.

The RedMagic Astra is the first reference profile, not the project identity.

# 0.5.0-dev observation

The NP05J exposes a cumulative KGSL `gpubusy` counter. DroidConverge samples it for tablet-wide GPU load in Android and through `droidconverge-gpu-status` in Ubuntu. The value includes Android, Anland and other clients; the firmware has not exposed a reliable per-chroot counter, so KDE System Monitor's missing per-process GPU graph is an acknowledged limitation.

NP05J exposes `cpu-*`, `gpuss-*`, `skin-msm-therm` and `battery` thermal zones and `/sys/kernel/fan/{fan_enable,fan_speed_level}`. The app displays only bounded read-only values. A single on-device sample showed the internal fan enabled at level 4; valid write ranges and cooler Bluetooth control remain untested. Other devices show only sensors they actually expose.

The NP05J alone has a tested KScreen scale/profile action: one virtual Anland output, 100% Desktop on HDMI and a configurable 170% Touch tablet default. Manual 170% to 100% transition and rollback were observed on 2026-09-18; automatic cable hotplug still needs a physical test. The MOSART USB mouse and SONiX USB keyboard accepted temporary `power/control=on` while routed, and the mouse restored `auto` on return. USB power behavior on other VID/PIDs is untested. Samsung, Motorola, Pixel and unknown devices do not receive this automatic KScreen profile.


RedMagic Astra: owner reports Anland can be moved to the HDMI monitor through
RedMagic **Schermo esteso** after opening Anland. ADB reports an Android HDMI
display and attached USB keyboard/mouse. The owner confirmed KDE pixels on
the monitor. Physical input behavior in KDE still requires manual confirmation.
Samsung, Motorola and Pixel remain
experimental. Rollback uses RedMagic's internal-screen selection and the app's
`Solo interno (app)`; no system display property is written.
The app requests Anland on the detected Android presentation display with a
public launch option and opens Android display settings. This does not invoke
a private RedMagic API or change persistent display mode. An Android HDMI
framebuffer capture on 2026-09-18 showed the full KDE desktop after managed
start and foregrounding Anland. The owner confirmed KDE on the monitor;
physical input and audio remain unverified. Android initially listed the hub
keyboard and mice without display association. DroidConverge's own privileged
helper associated the MOSART mouse and SONiX keyboard with HDMI and then the
internal display; `dumpsys input` confirmed both transitions. This requires
Magisk root approval for the app and is tested only on this RedMagic.

## External display capability matrix

| Family | Android display observation | Companion path | External test status |
|---|---|---|---|
| RedMagic Astra / nubia NP05J | Disconnected: ID 0, 1504x2400, density 360. USB-C to AOC 24G4: HDMI 1920x1080, `FLAG_PRESENTATION`; logical ID changed from 2 to 6 after reconnection | `InternalOnly` without cable; `SecondaryDisplayCompanion` with monitor | KDE pixels confirmed on physical monitor; Android input route/return tested by wireless ADB on 2026-09-18; KDE event delivery, hotplug, audio pending |
| Samsung DeX | Not measured | Manual desktop observation only | Experimental |
| Motorola Ready For / Smart Connect | Not measured | Manual desktop observation only | Experimental |
| Pixel | Not measured | Public API classification only | Experimental |
| Other Android | Not measured | `UnsupportedOrUnknown` when a display is visible without presentation support | Experimental |

No row asserts an extended KDE desktop. Adapter identity, orientation, input
and disconnect behavior still need recording after the physical test. See
`docs/EXTERNAL-DISPLAY.md` for the read-only ADB commands, expected observations
and rollback.

Future profiles should record:

- manufacturer/model
- SoC/GPU
- Android version
- kernel
- root method
- display information
- DRM/render nodes
- graphics compatibility
- thermal/power behavior
- input quirks
- external display behavior
- required permissions
- device-specific workarounds

Recommended path:

```text
profiles/<manufacturer>-<model>/
```
