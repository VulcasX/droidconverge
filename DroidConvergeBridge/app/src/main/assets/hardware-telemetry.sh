#!/system/bin/sh
# Hardware temperatures are shared by Android and the chroot, not Linux usage.
for zone in /sys/class/thermal/thermal_zone*; do
    [ -r "$zone/type" ] && [ -r "$zone/temp" ] || continue
    type=$(cat "$zone/type")
    case "$type" in
        cpu-*|gpuss-*|skin-msm-therm|battery)
            value=$(cat "$zone/temp")
            case "$value" in ''|*[!0-9]*) continue ;; esac
            printf 'TEMP %s %s\n' "$type" "$value"
            ;;
    esac
done
if [ -r /sys/kernel/fan/fan_enable ] && [ -r /sys/kernel/fan/fan_speed_level ]; then
    printf 'FAN %s %s\n' "$(cat /sys/kernel/fan/fan_enable)" "$(cat /sys/kernel/fan/fan_speed_level)"
fi
if [ -r /sys/class/kgsl/kgsl-3d0/gpubusy ]; then
    read -r busy total < /sys/class/kgsl/kgsl-3d0/gpubusy || true
    case "${busy:-}:${total:-}" in *[!0-9:]*) ;; *) printf 'GPU_BUSY %s %s\n' "$busy" "$total" ;; esac
fi
