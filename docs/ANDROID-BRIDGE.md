# Android Bridge architecture

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
