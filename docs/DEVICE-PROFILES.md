# Device profiles

The project is device-agnostic by design.

The RedMagic Astra is the first reference profile, not the project identity.

## External display capability matrix

| Family | Android display observation | Companion path | External test status |
|---|---|---|---|
| RedMagic Astra / nubia NP05J | Disconnected: one display (ID 0), 1504x2400, density 360; no active mirror target | `InternalOnly` at baseline; mirror/secondary unknown until cable test | External output untested in this cycle |
| Samsung DeX | Not measured | Manual desktop observation only | Experimental |
| Motorola Ready For / Smart Connect | Not measured | Manual desktop observation only | Experimental |
| Pixel | Not measured | Public API classification only | Experimental |
| Other Android | Not measured | `UnsupportedOrUnknown` when a display is visible without presentation support | Experimental |

No row asserts an extended KDE desktop. Adapter, monitor, orientation, input
and disconnect behavior must be recorded after the physical test. See
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
