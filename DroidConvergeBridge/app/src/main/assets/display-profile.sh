#!/system/bin/sh
set -eu
rootfs=/data/local/chroot-distro/ubuntu26
pid=$(pidof kwin_wayland | awk '{print $1}')
[ -n "$pid" ] || { echo NO_KWIN; exit 1; }
[ "$(readlink "/proc/$pid/root")" = "$rootfs" ] || { echo WRONG_ROOT; exit 1; }
bus=$(tr '\000' '\n' < "/proc/$pid/environ" | sed -n 's/^DBUS_SESSION_BUS_ADDRESS=//p' | head -n 1)
[ -n "$bus" ] || { echo NO_SESSION_BUS; exit 1; }

run_kde() {
    /system/bin/timeout 15 /system/bin/nsenter -t "$pid" -m -- \
        /system/bin/chroot "$rootfs" \
        /usr/bin/setpriv --reuid=1000 --regid=1000 --clear-groups \
        /usr/bin/env HOME=/home/android USER=android LOGNAME=android \
        PATH=/usr/local/bin:/usr/bin:/bin \
        LANG=C.UTF-8 XDG_RUNTIME_DIR=/run/user/1000 \
        DBUS_SESSION_BUS_ADDRESS="$bus" WAYLAND_DISPLAY=wayland-0 "$@"
}

output=$(run_kde /usr/bin/kscreen-doctor -o) || { echo KSCREEN_UNAVAILABLE; exit 1; }
[ "$(printf '%s\n' "$output" | grep -c 'anland-1')" = 1 ] || { echo UNSUPPORTED_OUTPUT; exit 1; }
old_scale=$(printf '%s\n' "$output" | grep 'Scale:' | tail -n 1 | grep -oE '[0-9]+([.][0-9]+)?$')
[ -n "$old_scale" ] || { echo SCALE_UNKNOWN; exit 1; }
if [ "${1:-status}" = status ]; then
    printf 'SCALE=%s\nOUTPUT=anland-1\n' "$old_scale"
    exit 0
fi
state_dir="$rootfs/home/android/.local/state/droidconverge"
previous_file="$state_dir/display-scale.previous"
if [ "$1" = rollback ]; then
    [ -r "$previous_file" ] || { echo NO_ROLLBACK; exit 1; }
    previous=$(cat "$previous_file")
    case "$previous" in ''|*[!0-9.]*) echo BAD_ROLLBACK; exit 1 ;; esac
    run_kde /usr/bin/kscreen-doctor "output.1.scale.$previous" >/dev/null || { echo ROLLBACK_FAILED; exit 1; }
    printf 'ROLLED_BACK=%s\n' "$previous"
    exit 0
fi
[ "$1" = apply ] || { echo INVALID_ACTION; exit 2; }
percent=${2:-}
mode=${3:-keep}
case "$percent" in ''|*[!0-9]*) echo INVALID_SCALE; exit 2 ;; esac
[ "$percent" -ge 80 ] && [ "$percent" -le 250 ] || { echo INVALID_SCALE; exit 2; }
case "$mode" in desktop|touch|keep) ;; *) echo INVALID_MODE; exit 2 ;; esac

# Keep the first original KWin config locally for manual rollback; never export it.
config="$rootfs/home/android/.config/kwinoutputconfig.json"
backup="$state_dir/kwinoutputconfig.before-auto.json"
umask 077
mkdir -p "$state_dir"
if [ -f "$config" ] && [ ! -e "$backup" ]; then cp "$config" "$backup"; chmod 600 "$backup"; fi
if [ -e "$backup" ]; then chmod 600 "$backup"; fi
printf '%s\n' "$old_scale" > "$previous_file"
scale=$(awk "BEGIN {printf \"%.2f\", $percent / 100}")
if ! run_kde /usr/bin/kscreen-doctor "output.1.scale.$scale" >/dev/null; then
    echo APPLY_FAILED
    exit 1
fi
new_scale=$(run_kde /usr/bin/kscreen-doctor -o | grep 'Scale:' | tail -n 1 | grep -oE '[0-9]+([.][0-9]+)?$') || true
new_percent=$(awk "BEGIN {printf \"%d\", $new_scale * 100 + 0.5}" 2>/dev/null || true)
if [ "$new_percent" != "$percent" ]; then
    run_kde /usr/bin/kscreen-doctor "output.1.scale.$old_scale" >/dev/null 2>&1 || true
    echo VERIFY_FAILED
    exit 1
fi
case "$mode" in
    desktop) run_kde /home/android/.local/bin/plasma-desktop-mode >/dev/null || { echo MODE_FAILED; exit 1; } ;;
    touch) run_kde /home/android/.local/bin/plasma-touch-mode >/dev/null || { echo MODE_FAILED; exit 1; } ;;
esac
printf 'APPLIED=%s\nPREVIOUS=%s\nMODE=%s\n' "$new_scale" "$old_scale" "$mode"
