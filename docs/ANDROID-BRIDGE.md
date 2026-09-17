# Android Bridge architecture

## Current state

The Android app runs a token-authenticated JSONL service on `127.0.0.1:8765`.
The unreleased display panel reads public `DisplayManager` state and can send
explicit, confirmed commands to the installed Termux session helper when the
user has opted in to Termux `RUN_COMMAND`. It does not add display operations
to the TCP protocol or use Shizuku/root for display detection. Details and
rollback: `docs/EXTERNAL-DISPLAY.md`.

## Target

Provide Linux with a small, auditable interface to Android services instead of relying on shared filesystem tricks.

```text
KDE / Maliit / Linux scripts
            │
            ▼
     astra-free bridge CLI
            │
            ▼
      Android IPC / Binder
            │
       ┌────┴────┐
       │         │
 Android APIs  Shizuku/Sui
```

The application will be native Android/Kotlin. Flutter may be used later for a UI, but the integration core should remain native because the difficult part is Android IPC, system APIs and permissions.

## Planned operations

```text
haptic
battery
wifi
bluetooth
wifi-settings
bluetooth-settings
anland-touch
anland-desktop
```

Privileged operations will use Shizuku/Sui only where normal Android APIs are insufficient.

## Why Shizuku matters

Shizuku exposes system APIs to normal apps through a Binder-based service using ADB/shell or root identity, avoiding repeated `su` process creation. Its API project explicitly supports Shizuku and Sui. The reference device already has Shizuku installed.

## Development rule

Every bridge feature must have:

- Android-side implementation
- Linux-side CLI/API
- permission model
- test command
- failure behavior
- documentation
- upstream API reference
