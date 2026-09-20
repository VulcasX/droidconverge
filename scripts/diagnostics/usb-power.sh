#!/system/bin/sh
# Read-only USB runtime power inventory. No serial numbers or file contents.
for device in /sys/bus/usb/devices/*; do
    [ -r "$device/idVendor" ] || continue
    vendor=$(cat "$device/idVendor")
    product=$(cat "$device/idProduct")
    control=$(cat "$device/power/control" 2>/dev/null || echo unknown)
    runtime=$(cat "$device/power/runtime_status" 2>/dev/null || echo unknown)
    delay=$(cat "$device/power/autosuspend_delay_ms" 2>/dev/null || echo unknown)
    printf '%s %s:%s control=%s runtime=%s delay_ms=%s\n' \
        "${device##*/}" "$vendor" "$product" "$control" "$runtime" "$delay"
done
