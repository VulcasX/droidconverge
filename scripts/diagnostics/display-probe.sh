#!/system/bin/sh
set -eu
rootfs=/data/local/chroot-distro/ubuntu26
pid=$(pidof kwin_wayland | awk '{print $1}')
[ -n "$pid" ] || { echo NO_KWIN; exit 1; }
[ "$(readlink "/proc/$pid/root")" = "$rootfs" ] || { echo WRONG_ROOT; exit 1; }
bus=$(tr '\000' '\n' < "/proc/$pid/environ" | sed -n 's/^DBUS_SESSION_BUS_ADDRESS=//p' | head -n 1)
[ -n "$bus" ] || { echo NO_SESSION_BUS; exit 1; }
/system/bin/timeout 15 /system/bin/nsenter -t "$pid" -m -- /system/bin/chroot "$rootfs" \
    /usr/bin/setpriv --reuid=1000 --regid=1000 --clear-groups /usr/bin/env \
    XDG_RUNTIME_DIR=/run/user/1000 \
    DBUS_SESSION_BUS_ADDRESS="$bus" \
    WAYLAND_DISPLAY=wayland-0 \
    /usr/bin/kscreen-doctor -o | grep -iE 'output:|scale:|mode:|geometry:|enabled:'
