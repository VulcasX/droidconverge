# DroidConverge Bridge

Android-side bridge for the [DroidConverge](https://github.com/VulcasX/droidconverge) project.

## Current milestone

**0.1.0-dev - haptic proof of concept**

This first version deliberately contains only one external bridge method:

```text
haptic
```

It is implemented through an exported Android `ContentProvider` and Android's `VibratorManager` API. `VibratorManager` was added in Android API 31 and requires `android.permission.VIBRATE`. The provider uses `ContentProvider.call()` as the small command-oriented IPC surface.

Android references:

- [ContentProvider](https://developer.android.com/guide/topics/providers/content-provider-creating)
- [VibratorManager](https://developer.android.com/reference/android/os/VibratorManager)
- [ContentResolver.call](https://developer.android.com/reference/android/content/ContentResolver)

## Development environment

The project is currently prepared for:

- Android Studio Quail 4 / 2026.1.4
- Android Gradle Plugin 9.4.0
- Gradle 9.6.0
- JDK 17
- compileSdk 36
- minSdk 31

See the Android documentation for the current AGP compatibility requirements.

- [AGP 9.4 compatibility](https://developer.android.com/build/releases/agp-9-4-0-release-notes)
- [AGP overview](https://developer.android.com/build/releases/about-agp)

## Security model in this development build

The provider currently accepts calls from:

- Android root UID 0
- Android shell UID 2000
- the app's own UID

This is intentional for the proof of concept. Before a public release, the authorization model will be tightened and documented.

## Build

Open ``DroidConvergeBridge`` in Android Studio and sync Gradle.

Then run the ``app`` configuration on a connected Android device or emulator.

Do not commit:

- APKs
- signing keys
- ``local.properties``
- private device data
- generated build output

unless they are intentionally published through an appropriate release or artifact workflow.

## IPC test

From an Android shell/root context after the APK is installed:

```bash
/system/bin/content call --uri content://org.droidconverge.bridge --method haptic
```

Expected result:

```text
status=ok
method=haptic
```

and a short click-like vibration on devices that expose a vibrator.

## Future bridge methods

Planned after the haptic proof is validated:

- ``battery``
- ``wifi``
- ``bluetooth``
- Android settings intents
- Anland mode control
- Shizuku/Sui-backed privileged operations where Android framework restrictions require them

## AI-assisted / vibe-coding workflow

DroidConverge is developed with AI-assisted iteration.

AI-generated code is not considered validated merely because it builds. Every bridge operation must be compiled, installed and tested on real hardware before it is promoted from experimental work to documented functionality.

## Licensing and attribution

``DroidConvergeBridge`` is part of the DroidConverge repository and is covered by the repository's project licensing and attribution policy.

See the repository root:

- ``LICENSE``
- ``LICENSE-DOCS.md``
- ``SOURCES.md``
- ``THIRD-PARTY-NOTICES.md``

The Android project also depends on third-party tooling and libraries whose own licenses remain applicable.
