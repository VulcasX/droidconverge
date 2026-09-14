# Device profiles

The project is device-agnostic by design.

The RedMagic Astra is the first reference profile, not the project identity.

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
