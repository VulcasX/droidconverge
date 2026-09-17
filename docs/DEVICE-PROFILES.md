# Device profiles

The project is device-agnostic by design.

The RedMagic Astra is the first reference profile, not the project identity.

## External display capability matrix

| Family | Android display observation | Companion path | External test status |
|---|---|---|---|
| RedMagic Astra / nubia NP05J | Disconnected: ID 0, 1504x2400, density 360. USB-C to AOC 24G4: HDMI ID 2, 1920x1080, `FLAG_PRESENTATION`; vendor `MirrorDisplayId=-1` | `InternalOnly` without cable; `SecondaryDisplayCompanion` with monitor | Android presentation pixels captured from HDMI display and rollback tested via wireless ADB on 2026-09-17; Termux `status` returned `UNKNOWN` for pre-existing session; physical monitor inspection, hotplug, input and managed KDE lifecycle pending |
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
