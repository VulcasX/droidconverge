#!/system/bin/sh
# Numeric read-only probe. Never prints command lines, names or environment.
rootfs=/data/local/chroot-distro/ubuntu26
total=$(awk 'NR==1 {for (i=2;i<=NF;i++) sum+=$i; printf "%.0f", sum}' /proc/stat)
mem_total=$(awk '/^MemTotal:/ {print $2; exit}' /proc/meminfo)
page_kb=$(($(getconf PAGESIZE) / 1024))
used_jiffies=0
rss_pages=0
count=0
for entry in /proc/[0-9]*; do
    [ "$(readlink "$entry/root" 2>/dev/null)" = "$rootfs" ] || continue
    [ -r "$entry/stat" ] || continue
    sample=$(awk -F') ' '{split($2, a, " "); printf "%.0f %.0f", a[12]+a[13], a[22]}' "$entry/stat" 2>/dev/null) || continue
    set -- $sample
    [ "$#" -eq 2 ] || continue
    used_jiffies=$((used_jiffies + $1))
    rss_pages=$((rss_pages + $2))
    count=$((count + 1))
done
printf 'TOTAL=%s\nCHROOT=%s\nRSS_KB=%s\nMEM_TOTAL_KB=%s\nPROCESSES=%s\n' \
    "$total" "$used_jiffies" "$((rss_pages * page_kb))" "$mem_total" "$count"
