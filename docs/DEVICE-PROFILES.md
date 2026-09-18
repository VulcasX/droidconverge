# Device profiles

The project is device-agnostic by design.

The RedMagic Astra is the first reference profile, not the project identity.

# 0.5.0-dev observation

RedMagic Astra: owner reports Anland can be moved to the HDMI monitor through
RedMagic **Schermo esteso** after opening Anland. ADB reports an Android HDMI
display and attached USB keyboard/mouse; the app's new peripheral panel reports
public Android input facts only. KDE picture and input behavior on the physical
monitor still require manual confirmation. Samsung, Motorola and Pixel remain
experimental. Rollback uses RedMagic's internal-screen selection and the app's
`Solo interno (app)`; no system display property is written.
The app requests Anland on the detected Android presentation display with a
public launch option and opens Android display settings. This does not invoke
a private RedMagic API or change persistent display mode. An Android HDMI
framebuffer capture on 2026-09-18 showed the full KDE desktop after managed
start and foregrounding Anland. The owner confirmed KDE on the monitor;
physical input and audio remain unverified. Android listed the hub keyboard
and mice without display association. MagicDesk input routing is available as
an optional external control; it has not yet been verified with Anland.

## External display capability matrix

| Family | Android display observation | Companion path | External test status |
|---|---|---|---|
| RedMagic Astra / nubia NP05J | Disconnected: ID 0, 1504x2400, density 360. USB-C to AOC 24G4: HDMI 1920x1080, `FLAG_PRESENTATION`; logical ID changed from 2 to 6 after reconnection | `InternalOnly` without cable; `SecondaryDisplayCompanion` with monitor | Android presentation capture and rollback, plus managed Anland/Plasma start, stop and restart tested by wireless ADB on 2026-09-17; `plasmashell`, physical monitor inspection, hotplug and keyboard/mouse input pending |
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
