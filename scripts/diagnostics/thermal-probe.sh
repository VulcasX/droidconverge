#!/system/bin/sh
# Read-only thermal sensor inventory; no personal identifiers.
for zone in /sys/class/thermal/thermal_zone*; do
    [ -r "$zone/type" ] && [ -r "$zone/temp" ] || continue
    type=$(cat "$zone/type")
    case "$type" in
        *gpu*|*GPU*|*cpu*|*CPU*|*battery*|*BATT*|*skin*|*SKIN*)
            printf '%s %s %s\n' "${zone##*/}" "$type" "$(cat "$zone/temp")"
            ;;
    esac
done
