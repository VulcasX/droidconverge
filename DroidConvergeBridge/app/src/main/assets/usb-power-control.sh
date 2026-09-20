#!/system/bin/sh
set -eu
action=${1:-}
vendor=${2:-}
product=${3:-}
case "$action" in get|set) ;; *) echo INVALID_ACTION; exit 2 ;; esac
case "$vendor$product" in ''|*[!0-9a-f]*) echo INVALID_ID; exit 2 ;; esac
[ "${#vendor}" -eq 4 ] && [ "${#product}" -eq 4 ] || { echo INVALID_ID; exit 2; }
if [ "$action" = set ]; then
    case "${4:-}" in on|auto) ;; *) echo INVALID_VALUE; exit 2 ;; esac
fi
matched=
for device in /sys/bus/usb/devices/*; do
    [ -r "$device/idVendor" ] || continue
    [ "$(cat "$device/idVendor")" = "$vendor" ] || continue
    [ "$(cat "$device/idProduct")" = "$product" ] || continue
    [ -z "$matched" ] || { echo AMBIGUOUS_DEVICE; exit 1; }
    matched=$device
done
[ -n "$matched" ] || { echo DEVICE_MISSING; exit 1; }
control="$matched/power/control"
[ -r "$control" ] || { echo CONTROL_MISSING; exit 1; }
if [ "$action" = set ]; then
    printf '%s\n' "$4" > "$control"
    [ "$(cat "$control")" = "$4" ] || { echo VERIFY_FAILED; exit 1; }
fi
printf 'CONTROL=%s\n' "$(cat "$control")"
