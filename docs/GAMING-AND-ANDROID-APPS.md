# Gaming and Android applications in Ubuntu

## Android application menu

`droidconverge-android-apps sync` asks the authenticated loopback Bridge for launchable applications and creates KDE entries under `~/.local/share/applications/droidconverge-android/`. Only package name and launcher label are returned. The command never exports APKs, account data or application storage. Each entry calls `android-launch`; the Bridge checks that the requested package still has a launcher activity before Android starts it.

Run `sync` again after installing or removing Android apps. Remove the generated directory to roll back. Wi-Fi and Bluetooth controls use the same CLI: `wifi status|on|off`, `bluetooth status|on|off`, `wifi-settings`, and `bluetooth-settings`. Ubuntu already shares Android's network connection through the host kernel. Raw Wi-Fi or Bluetooth device passthrough is not enabled because Android owns the radios and running a second network/Bluetooth stack could disrupt the tablet.

## ARM64 software store and video diagnostics

`install-desktop-software.sh` installs Plasma Discover, PackageKit/AppStream and ARM64 Mesa/FFmpeg diagnostic packages from the configured Ubuntu repositories. Discover must show the Ubuntu APT backend and `dpkg --print-architecture` must remain `arm64`. No x86 repository is added.

`graphics-capabilities` reports render nodes, video nodes, Vulkan/VA-API tools and FFmpeg hardware backends. Installing user-space packages does not prove hardware video decoding: the Anland session still needs a compatible kernel video device or driver. Compare CPU load and `ffmpeg` output with a known sample before declaring decode supported. Package rollback is printed by the installer.

`droidconverge-gpu-status` samples KGSL for one second inside Ubuntu. It reports whole-tablet load. KDE System Monitor cannot show per-process Ubuntu GPU usage until the Android KGSL stack exposes accounting compatible with KSystemStats; the script and app keep this limitation visible.

On RedMagic Astra NP05J, the KGSL node resets when read. The tested calculation is therefore the direct busy/total ratio from one read rather than a delta between cumulative samples. Both the Android panel and Ubuntu helper showed a nonzero tablet-wide value. This remains shared device activity.

The 2026-09-19 device check found `/dev/video32` as Qualcomm's `msm_vidc_decoder`; FFmpeg selected it for a synthetic H.264 stream but failed while allocating capture buffers. A temporary test of only the nonsecure `system` and `qcom,system` DMA heaps did not change the result, and their original modes were restored. VA-API also lacked a working Qualcomm driver. Hardware video decoding is therefore detected but not operational.

## Steam and games

Steam is x86/x86-64 software on an ARM64 Ubuntu chroot. The experimental installer therefore requires a reviewed Box64 commit or tag in `DROIDCONVERGE_BOX64_REF`, builds official Box64 with Box32, and then invokes Box64's own Steam installer. It refuses to overwrite an existing source directory. Run `--check` first.

On 2026-09-19 the RedMagic built official Box64 tag `v0.4.5-1` (`e99ca51`), installed the upstream Steam payload and created a KDE entry. Android exposes an empty `binfmt_misc`, so the DroidConverge launcher explicitly runs the x86 Bash shim through Box64. The Steam client then remained running and reported its requirements satisfied, but logged unsupported synchronization assertions. Login and a harmless game have not been tested; gaming stays experimental. Roll back only after backing up game data: remove the generated launcher and Steam user directories, then review the upstream uninstall helper before using it.

Game compatibility and Vulkan acceleration vary; keep game libraries backed up before rollback. DroidConverge does not vendor Box64 or Steam source/binaries.

The same live check generated 64 KDE entries from the tablet's launchable Android packages and successfully opened DroidConverge from Ubuntu. Wi-Fi and Bluetooth status both returned enabled. These tests validate the Bridge path, not raw radio passthrough.
