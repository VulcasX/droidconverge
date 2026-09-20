#!/bin/bash
# Read-only graphics/video capability report for the active chroot session.
set -u
printf 'ARCH=%s\n' "$(uname -m)"
for tool in glxinfo eglinfo vulkaninfo vainfo ffmpeg; do
    command -v "$tool" >/dev/null && printf '%s=%s\n' "${tool^^}" "$(command -v "$tool")" || printf '%s=MISSING\n' "${tool^^}"
done
printf 'DRI='; find /dev/dri -maxdepth 1 -type c -printf '%f ' 2>/dev/null; echo
printf 'VIDEO='; find /dev -maxdepth 1 -type c -name 'video*' -printf '%f ' 2>/dev/null; echo
command -v ffmpeg >/dev/null && ffmpeg -hide_banner -hwaccels 2>/dev/null | sed -n '2,$p' || true
command -v vainfo >/dev/null && timeout 8 vainfo 2>&1 | sed -n '1,25p' || true
