#!/usr/bin/env bash
set -u
OUT="${1:-$HOME/droidconverge-state-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$OUT"
run() { local name="$1"; shift; { echo '$' "$@"; "$@" 2>&1 || true; } > "$OUT/$name.txt"; }
run uname uname -a
run getprop getprop
run termux-info termux-info
run chroot-distro-list chroot-distro list
printf 'model=%s\nandroid=%s\nsdk=%s\nabi=%s\n' \
  "$(getprop ro.product.model 2>/dev/null)" \
  "$(getprop ro.build.version.release 2>/dev/null)" \
  "$(getprop ro.build.version.sdk 2>/dev/null)" \
  "$(getprop ro.product.cpu.abi 2>/dev/null)" > "$OUT/android-summary.txt"
if command -v chroot-distro >/dev/null 2>&1; then
  chroot-distro command ubuntu26 "cat /etc/os-release; echo; uname -a" > "$OUT/ubuntu.txt" 2>&1 || true
  chroot-distro command ubuntu26 "dpkg-query -W -f='${Package}\t${Version}\n' | sort" > "$OUT/ubuntu-packages.txt" 2>&1 || true
  chroot-distro command ubuntu26 "plasmashell --version; echo; kwin_wayland --version; echo; apt-mark showhold" > "$OUT/desktop-state.txt" 2>&1 || true
fi
cat > "$OUT/README.txt" <<'EOT'
Generated device snapshot. Review before sharing publicly.
Remove serial numbers, Android IDs, account information, tokens and personal data.
EOT
echo "Snapshot written to $OUT"
