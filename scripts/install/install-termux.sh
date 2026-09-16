#!/data/data/com.termux/files/usr/bin/bash
set -e

ROOT="${DROIDCONVERGE_REPO_ROOT:-$HOME/droidconverge}"

install -Dm755 "$ROOT/scripts/termux/anland-bridge.sh" \
    "$HOME/anland-bridge.sh"

install -Dm755 "$ROOT/scripts/termux/start-ubuntu-kde.sh" \
    "$HOME/start-ubuntu-kde.sh"

install -Dm755 "$ROOT/scripts/termux/startplasma-anland.sh" \
    "$HOME/startplasma-anland.sh"

mkdir -p "$HOME/.shortcuts/tasks" "$HOME/.termux/tasker"

install -Dm755 "$ROOT/scripts/termux/Ubuntu-KDE" \
    "$HOME/.shortcuts/tasks/Ubuntu-KDE"

install -Dm755 "$ROOT/scripts/termux/tasker-haptic" \
    "$HOME/.termux/tasker/haptic"

install -Dm755 "$ROOT/scripts/termux/anland-haptic-test" \
    "$HOME/anland-haptic-test"

echo "DroidConverge Termux integration installed."
