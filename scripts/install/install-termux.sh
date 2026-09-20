#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
[[ "${PREFIX:-}" == /data/data/com.termux/files/usr ]] || {
    printf '%s\n' "Run this installer inside the GitHub Termux app." >&2
    exit 1
}
PREFIX_BIN="$PREFIX/bin"
for source in start-ubuntu-kde.sh startplasma-anland.sh anland-bridge.sh anland-haptic-test droidconverge-session; do
    [[ -f "$ROOT/scripts/termux/bin/$source" ]] || { printf 'Missing source: %s\n' "$source" >&2; exit 1; }
done
backup="$HOME/.local/state/droidconverge/installer-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup/bin" "$backup/shortcuts" "$backup/tasker"
for name in start-ubuntu-kde.sh startplasma-anland.sh anland-bridge.sh anland-haptic-test droidconverge-session; do
    [[ ! -e "$PREFIX_BIN/$name" ]] || cp -p "$PREFIX_BIN/$name" "$backup/bin/$name"
done
[[ ! -e "$HOME/.shortcuts/tasks/Ubuntu-KDE" ]] || cp -p "$HOME/.shortcuts/tasks/Ubuntu-KDE" "$backup/shortcuts/Ubuntu-KDE"
[[ ! -e "$HOME/.termux/tasker/haptic" ]] || cp -p "$HOME/.termux/tasker/haptic" "$backup/tasker/haptic"
mkdir -p "$PREFIX_BIN"

install -m 0755 "$ROOT/scripts/termux/bin/start-ubuntu-kde.sh" "$PREFIX_BIN/start-ubuntu-kde.sh"
install -m 0755 "$ROOT/scripts/termux/bin/startplasma-anland.sh" "$PREFIX_BIN/startplasma-anland.sh"
install -m 0755 "$ROOT/scripts/termux/bin/anland-bridge.sh" "$PREFIX_BIN/anland-bridge.sh"
install -m 0755 "$ROOT/scripts/termux/bin/anland-haptic-test" "$PREFIX_BIN/anland-haptic-test"
install -m 0755 "$ROOT/scripts/termux/bin/droidconverge-session" "$PREFIX_BIN/droidconverge-session"

mkdir -p "$HOME/.shortcuts/tasks" "$HOME/.termux/tasker"
install -m 0755 "$ROOT/scripts/termux/.shortcuts/tasks/Ubuntu-KDE" "$HOME/.shortcuts/tasks/Ubuntu-KDE"
install -m 0755 "$ROOT/scripts/termux/.termux/tasker/haptic" "$HOME/.termux/tasker/haptic"

printf '%s\n' "Termux integration installed."
printf '%s\n' "Start with: start-ubuntu-kde.sh"
printf 'Previous files, if any: %s\n' "$backup"
printf '%s\n' "Check with: droidconverge-session status"
