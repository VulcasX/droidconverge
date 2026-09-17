# Linux haptics integration

DroidConverge can connect Linux input/haptic events to the Android Bridge.

## Data path

```text
Maliit / Plasma Mobile input event
        |
        v
DroidConverge Linux integration
        |
        | TCP 127.0.0.1:8765
        | JSON line + token
        v
DroidConverge Android Bridge
        |
        v
Android VibratorManager
```

## Linux configuration

The client configuration is stored in:

```text
~/.config/droidconverge.json
```

The repository contains only:

```text
configs/droidconverge.json.example
```

The example is sanitized. A real token must never be committed.

## Maliit

The preserved Maliit source under `integrations/maliit/` uses the Android ContentProvider haptic path. The preserved before/after files are identical, so there is no verified TCP patch to apply in this prerelease. TCP client integration with the token-authenticated Bridge remains work in progress.

## Plasma Mobile

Selected Plasma Mobile integration sources are retained under `integrations/plasma-mobile/`. They are not a full upstream source tree.

## Verification

Verify each layer separately:

1. Android Bridge responds to `ping`.
2. Android Bridge responds to a direct `haptic` action.
3. Linux configuration contains the correct token locally.
4. Verify the selected Linux component against its documented IPC path.
5. A real key/input event produces the expected haptic response on the reference device.

## Security note

Loopback binding limits the Bridge to the local device, but the token is still a bearer credential for the local API. Protect the configuration file and do not copy the token into issue reports, commits or screenshots.
