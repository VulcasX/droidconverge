#!/bin/bash
# ARM64-only desktop store and graphics user-space packages. Run as root in the chroot.
set -euo pipefail
[[ $(id -u) == 0 ]] || { echo 'Run as root inside the chroot.' >&2; exit 1; }
[[ $(dpkg --print-architecture) == arm64 ]] || { echo 'ARM64 chroot required.' >&2; exit 1; }
apt-get update
apt-get install -y --no-install-recommends plasma-discover packagekit packagekit-tools appstream \
    mesa-utils mesa-vulkan-drivers vulkan-tools ffmpeg vainfo mesa-va-drivers
echo 'Discover and ARM64 graphics diagnostics installed.'
echo 'Hardware video decode still requires a compatible /dev/video or VA-API driver; verify with graphics-capabilities.'
echo 'Rollback: apt-get remove plasma-discover packagekit packagekit-tools appstream vulkan-tools vainfo mesa-va-drivers'
