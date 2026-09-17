# DroidConverge Bridge

The Android application serves a token-authenticated JSON-line protocol on `127.0.0.1:8765`. It also retains a restricted Android ContentProvider haptic entry point for the earlier Linux integration prototype.

## Build and test

Use the repository Gradle wrapper with a JDK and Android SDK compatible with the project:

```powershell
cd DroidConvergeBridge
.\gradlew.bat testDebugUnitTest assembleDebug
```

The build output is `app/build/outputs/apk/debug/app-debug.apk`. This development APK is debug-signed. The Windows installer at `scripts/install/install-android-bridge.ps1` builds and installs it over ADB.

## Security

The TCP service binds to loopback and requires the token generated in the Android app. Keep the token in local configuration with restricted access. The ContentProvider accepts Android root, shell, and the app UID for its haptic method; it is intended for the development device.

See `docs/ANDROID-BRIDGE.md` and `docs/RELEASE-0.3.0.md` for protocol and release scope.
