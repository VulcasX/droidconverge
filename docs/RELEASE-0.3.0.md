# DroidConverge 0.3.0-dev release

This release consolidates the Android Bridge proof of concept and the preserved
Termux/Ubuntu integration from the 2026-09-15 tablet checkpoint.

Included:
- Android Bridge TCP service on `127.0.0.1:8765` with persistent authentication token.
- `ping`, `haptic`, `vibrate`, `battery`, `wifi`, `bluetooth`, and `notify` actions.
- Termux startup/Anland integration scripts.
- Ubuntu/KDE/Plasma mode scripts.
- Maliit DroidConverge haptic TCP patch.
- Sanitized example configuration without a real token.
- Reproducible Android, Termux and Ubuntu installation helpers.

Not included:
- Raw checkpoint archives.
- Upstream Maliit/Plasma Mobile source trees.
- Build directories and locally generated binaries.
- Real bridge tokens or personal configuration.

Known limitation:
`durationMs` is intentionally not part of the Bridge protocol yet. The existing
settings UI may contain duration fields, but the TCP request does not expose or
consume a duration parameter in this release.

Security:
The bridge is intended for rooted personal devices and binds to loopback only.
Protect the authentication token and never commit a real `droidconverge.json`.

This is a development/prerelease checkpoint rather than a Play Store production
release. Distribution outside the repository should use a properly signed APK.
