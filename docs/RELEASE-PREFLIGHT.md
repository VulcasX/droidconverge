# Release preflight

Use this checklist before committing or publishing a release.

## Source integrity

- [ ] `git status` is understood.
- [ ] no raw checkpoint archive is tracked.
- [ ] no personal backup is tracked.
- [ ] no real Bridge token is tracked.
- [ ] no generated build directory is tracked.
- [ ] no temporary PowerShell recovery/finalization script is tracked unless intentionally part of the project.
- [ ] upstream source trees are not duplicated into the repository unnecessarily.

## Android Bridge

- [ ] application builds with the repository Gradle wrapper.
- [ ] APK installs through ADB.
- [ ] Bridge binds to `127.0.0.1:8765`.
- [ ] token generation and regeneration work.
- [ ] `ping` works.
- [ ] haptic test works on the target device.
- [ ] rooted Wi-Fi/Bluetooth actions are documented as optional/privileged behavior.

## Termux / Ubuntu

- [ ] Termux installer is repeatable.
- [ ] Ubuntu installer is repeatable.
- [ ] Anland socket discovery is documented.
- [ ] `/tmp` bind mount is documented.
- [ ] shortcut/tasker entries are installed without embedding secrets.

## Linux integrations

- [ ] Maliit/Plasma Mobile integration source is present.
- [ ] any published patches are nonempty and reproducible.
- [ ] sanitized config example is present.
- [ ] build instructions are documented.

## Documentation

- [ ] root README matches the actual release scope.
- [ ] installation guide matches the scripts.
- [ ] limitations are explicit.
- [ ] disclaimers are present.
- [ ] unsupported features are not described as complete.

## Release

- [ ] clean build from a fresh checkout succeeds.
- [ ] release APK is generated.
- [ ] release notes are written.
- [ ] Git tag/version is consistent.
- [ ] published artifacts contain no secrets or personal data.
