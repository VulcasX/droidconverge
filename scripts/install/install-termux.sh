#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PREFIX_BIN="${PREFIX}/bin"
mkdir -p "$PREFIX_BIN"

install -m 0755 "$ROOT/scripts/termux/bin/start-ubuntu-kde.sh" "$PREFIX_BIN/start-ubuntu-kde.sh"
install -m 0755 "$ROOT/scripts/termux/bin/startplasma-anland.sh" "$PREFIX_BIN/startplasma-anland.sh"
install -m 0755 "$ROOT/scripts/termux/bin/anland-bridge.sh" "$PREFIX_BIN/anland-bridge.sh"
install -m 0755 "$ROOT/scripts/termux/bin/anland-haptic-test" "$PREFIX_BIN/anland-haptic-test"

mkdir -p "$HOME/.shortcuts/tasks" "$HOME/.termux/tasker"
install -m 0755 "$ROOT/scripts/termux/.shortcuts/tasks/Ubuntu-KDE" "$HOME/.shortcuts/tasks/Ubuntu-KDE"
install -m 0755 "$ROOT/scripts/termux/.termux/tasker/haptic" "$HOME/.termux/tasker/haptic"

printf '%s\n' "Termux integration installed."
printf '%s\n' "Start with: start-ubuntu-kde.sh"
