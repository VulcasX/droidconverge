# Unreleased (0.5.0-dev development)

- Show connected external Android input devices in the internal panel and
  provide a shortcut to Android settings. RedMagic extended-screen routing of
  Anland remains a manual vendor action.
- Add a Termux interactive installer for repository helpers, Ubuntu account
  and targeted desktop packages, with an optional desktop-app choice and
  fast-forward repository update. It checks pre-existing root, Anland and
  Ubuntu chroot before writes; clean-device end-to-end validation is pending.
- Incorporate the newer `main` Anland audio lifecycle and Plasma Mobile logout
  integration; the guided installer includes the logout helper on updates.

## 0.3.0-dev - 2026-09-15

- Consolidated the Android Bridge TCP service and authentication model.
- Recovered and packaged the Termux/Ubuntu startup integration from the tablet checkpoint.
- Preserved selected Maliit/Plasma Mobile integration sources for further work.
- Added Android, Termux and Ubuntu installation helpers.
- Added release/security documentation and sanitized configuration example.
# Changelog

## 0.4.0-dev - 2026-09-17

- Added five capability paths and an experimental Android display/session panel. On RedMagic Astra, a USB-C HDMI display exposed a separate presentation surface; its companion content and in-app rollback were verified over wireless ADB.
- Added opt-in Termux `RUN_COMMAND` session control with a fallback for an existing executable `~/start-ubuntu-kde.sh`. Managed start, stop and restart were tested on RedMagic; process identity checks prevent stopping an unrelated Anland session.
- Fixed an incomplete stop that left KDE and Anland running, and fixed stale panel results during asynchronous Termux commands.
- Removed nullable `JSONObject.optString` type warnings from the Bridge parser without changing the optional-field contract.
- Aligned the Ping response and app label with the Gradle version after a tablet Ping test found a stale `0.3.0-dev` response.
- Added an explicit ADB serial option to the Android installer and wireless ADB instructions for USB-C display testing.
- Recovered a selective Maliit TCP haptic patch from the tablet checkpoint and verified that it applies to the matching source. Linux build and runtime validation remain pending.
- Removed duplicate Termux/Ubuntu script copies and the obsolete installer; documented canonical install paths and rollback.
- KDE `plasmashell`, physical monitor inspection, hotplug and keyboard/mouse input remain unverified. No extended KDE desktop support is claimed.


- public project bootstrap
- device-agnostic project identity
- comprehensive landing README
- Touch/Desktop mode documentation
- Android Bridge architecture
- AI-assisted/vibe-coding workflow documented
- upstream attribution structure
