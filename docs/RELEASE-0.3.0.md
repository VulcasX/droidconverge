# DroidConverge 0.3.0-dev prerelease

## Scope

This release consolidates the Android Bridge and the Android/Linux startup and haptic integration work recovered from the development checkpoint.

The attached `DroidConvergeBridge-0.3.0-dev-debug.apk` is a debug-signed development build. It is suitable for testing on the reference device and is not a production-signed distribution.

SHA-256: `c1e5bf83f49e0c1be48dece87782099b0a2c54f22e19b448dba206fea44efcf3`

## Included

- Android Bridge service and local TCP/JSON protocol
- token-authenticated requests
- haptic and vibration actions
- battery, Wi-Fi, Bluetooth and notification actions
- Termux/Anland startup helpers
- Ubuntu/KDE startup and tablet/desktop helpers
- selected Linux haptic integration sources
- installation scripts and reproducibility documentation

## Intentionally deferred

- external display support/selection
- additional device-specific integrations
- final Play Store publication packaging
- verified Maliit TCP client patch; the preserved before/after files are identical

## Security

The repository must contain only sanitized examples. Device tokens and private configuration files stay on the device.

## Compatibility

This release targets the development environment used to validate the project. Hardware-specific graphics paths, GPU nodes and privileged Android actions may require adaptation on other devices.

## Verification

`testDebugUnitTest` and `assembleDebug` passed with Gradle 9.6.0. The APK installed successfully over ADB on the RedMagic Astra. Termux and Ubuntu installers passed shell syntax checks; a full clean installation and Linux haptic event test were not performed for this prerelease.
