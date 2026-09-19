# Gaming and Android applications in Ubuntu

## Android application menu

`droidconverge-android-apps sync` asks the authenticated loopback Bridge for launchable applications and creates KDE entries under `~/.local/share/applications/droidconverge-android/`. Only package name and launcher label are returned. The command never exports APKs, account data or application storage. Each entry calls `android-launch`; the Bridge checks that the requested package still has a launcher activity before Android starts it.

Run `sync` again after installing or removing Android apps. Remove the generated directory to roll back. Wi-Fi and Bluetooth controls use the same CLI: `wifi status|on|off`, `bluetooth status|on|off`, `wifi-settings`, and `bluetooth-settings`. Ubuntu already shares Android's network connection through the host kernel. Raw Wi-Fi or Bluetooth device passthrough is not enabled because Android owns the radios and running a second network/Bluetooth stack could disrupt the tablet.

## ARM64 software store and video diagnostics

`install-desktop-software.sh` installs Plasma Discover, PackageKit/AppStream and ARM64 Mesa/FFmpeg diagnostic packages from the configured Ubuntu repositories. Discover must show the Ubuntu APT backend and `dpkg --print-architecture` must remain `arm64`. No x86 repository is added.

`graphics-capabilities` reports render nodes, video nodes, Vulkan/VA-API tools and FFmpeg hardware backends. Installing user-space packages does not prove hardware video decoding: the Anland session still needs a compatible kernel video device or driver. Compare CPU load and `ffmpeg` output with a known sample before declaring decode supported. Package rollback is printed by the installer.

`droidconverge-gpu-status` samples KGSL for one second inside Ubuntu. It reports whole-tablet load. KDE System Monitor cannot show per-process Ubuntu GPU usage until the Android KGSL stack exposes accounting compatible with KSystemStats; the script and app keep this limitation visible.

## Steam and games

Steam is x86/x86-64 software on an ARM64 Ubuntu chroot. The experimental installer therefore requires a reviewed Box64 commit or tag in `DROIDCONVERGE_BOX64_REF`, builds official Box64 with Box32, and then invokes Box64's own Steam installer. It refuses to overwrite an existing source directory. Run `--check` first. This path is not yet device-tested and must not be enabled by the general installer until Steam opens, signs in and launches a harmless test title on the RedMagic.

Box64 documents that Linux Steam needs Box86 or Box32 with binfmt enabled. Game compatibility and Vulkan acceleration vary; keep game libraries backed up before rollback. DroidConverge does not vendor Box64 or Steam source/binaries.
