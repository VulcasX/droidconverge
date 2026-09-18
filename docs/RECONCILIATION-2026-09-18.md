# PC, GitHub and tablet reconciliation — 2026-09-18

This report incorporates the four temporary handoff notes supplied through
Google Drive. Their commit/version claims were checked against live state;
they are historical observations rather than build instructions.

| Source | Verified state |
|---|---|
| GitHub `main` | `34f5f9c`, Plasma Mobile logout quick setting; parent commits include restart-safe Anland audio lifecycle and its test notes. |
| PC `codex/external-display` before integration | `a2d87bb`, published `0.4.0-dev`; an uncommitted `0.5.0-dev` app/installer change set was under test. |
| Tablet checkpoint | `/sdcard/DroidConverge-backups/` contains a project source tar named for `cfd2fbf` and older Termux/Ubuntu archives. No newer loose project source was found in the root inventory. Archives were not imported wholesale. |
| Installed Android Bridge | `versionCode=3`, `versionName=0.5.0-dev`, installed from the local PC build during the current development run. The Drive notes' older `0.3.0-dev` comparison predated that installation. |

The `main` changes are independent of the experimental Android display branch
but its new `scripts/ubuntu/start-anland-plasma.sh` owns the working
PipeWire/WirePlumber lifecycle. Integration must preserve that version. The
Plasma logout integration also belongs to the combined line. Do not replace
either with an older snapshot from the tablet checkpoint.

## Hardware knowledge retained for later platform work

The Drive hardware note reports NP05J fan nodes under `/sys/kernel/fan/`,
stock `cn.nubia.fan` services, AW22xxx LED controls, qcom-battery charging
nodes and a privileged accessory package. These are research leads, not
permissions to write sysfs. Values and service semantics require independent
read-only verification on the current firmware. No third-party thermal module
was run and no upstream source was copied.

The proposed next platform milestone is a shared Linux service that owns the
Bridge token and exposes semantic capabilities to Plasma Mobile and Desktop.
QML must not access the raw token. Begin with explicit capabilities and
read-only fan state, then mock tests and device validation; defer fan writes,
bypass charging, RGB registers and external cooler control until semantics and
rollback are established. Candidate public projects for a separate licensed
research pass: NubiaParts, RedMagicFanControl/redmagicfancontrold, Kelvin,
RedMagic-FanExtreme, RedMagic8SPro-LineageOS and the verified current
RedmagicCooler repository. Record exact commits and licenses before reuse.

## Current installation/display task

RedMagic exposes an HDMI Android display and USB input devices. The owner
reports that Anland reaches the monitor through RedMagic **Schermo esteso**.
The Android companion button only shows a status presentation; it does not
move Anland. The 0.5.0-dev work adds public input enumeration and a Termux
guided installer. The reference tablet passed an installer `--check` and the
app build/UI check. Applying the installer to an untouched second device,
physical KDE picture and input routing remain validation gates. Rollback and
steps are in `docs/INSTALLATION.md` and `docs/EXTERNAL-DISPLAY.md`.
