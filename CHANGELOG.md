## 0.3.0-dev - 2026-09-15

- Consolidated the Android Bridge TCP service and authentication model.
- Recovered and packaged the Termux/Ubuntu startup integration from the tablet checkpoint.
- Preserved selected Maliit/Plasma Mobile integration sources for further work.
- Added Android, Termux and Ubuntu installation helpers.
- Added release/security documentation and sanitized configuration example.
# Changelog

## Unreleased

- Recovered a real, selective Maliit TCP haptic patch from the tablet source and verified that it applies to its matching backup. Runtime validation remains pending.
- Removed duplicate Termux/Ubuntu script copies and the obsolete Termux installer; documented the canonical install paths.
- Added an experimental Android display/session companion panel with public display detection and an opt-in Termux command path. Wireless ADB confirmed a RedMagic Astra secondary presentation window on a connected AOC monitor and its in-app rollback; KDE and input validation remain pending.
- Added an explicit ADB serial option to the Android installer for wireless multi-device setups.
- Verified companion pixels on the HDMI display and Termux status delivery on RedMagic Astra. A pre-existing unmanaged Anland session returned `UNKNOWN` and was left untouched.


- public project bootstrap
- device-agnostic project identity
- comprehensive landing README
- Touch/Desktop mode documentation
- Android Bridge architecture
- AI-assisted/vibe-coding workflow documented
- upstream attribution structure
