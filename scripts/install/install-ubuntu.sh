#!/usr/bin/env bash
set -e

ROOT="${DROIDCONVERGE_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

install -Dm755 "$ROOT/scripts/ubuntu/plasma/desktop-mode.sh" \
    "$HOME/desktop-mode.sh"

install -Dm755 "$ROOT/scripts/ubuntu/plasma/tablet-mode.sh" \
    "$HOME/tablet-mode.sh"

install -Dm755 "$ROOT/scripts/ubuntu/plasma/toggle-tablet-mode.sh" \
    "$HOME/toggle-tablet-mode.sh"

install -Dm755 "$ROOT/scripts/ubuntu/plasma/true-tablet-mode.sh" \
    "$HOME/true-tablet-mode.sh"

install -Dm755 "$ROOT/scripts/ubuntu/plasma/reset-plasma-default.sh" \
    "$HOME/reset-plasma-default.sh"

install -Dm755 "$ROOT/scripts/ubuntu/plasma/start-anland-plasma.sh" \
    "$HOME/start-anland-plasma.sh"

install -Dm644 "$ROOT/scripts/ubuntu/plasma/kwin-tablet-mode.py" \
    "$HOME/kwin-tablet-mode.py"

install -Dm755 "$ROOT/scripts/ubuntu/bin/plasma-desktop-mode" \
    "$HOME/.local/bin/plasma-desktop-mode"

install -Dm755 "$ROOT/scripts/ubuntu/bin/plasma-toggle-mode" \
    "$HOME/.local/bin/plasma-toggle-mode"

install -Dm755 "$ROOT/scripts/ubuntu/bin/plasma-touch-mode" \
    "$HOME/.local/bin/plasma-touch-mode"

echo "DroidConverge Ubuntu/Plasma integration installed."
