#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TARGET_HOME="${DROIDCONVERGE_TARGET_HOME:-/home/android}"
LOCAL_BIN="${DROIDCONVERGE_LOCAL_BIN:-$HOME/.local/bin}"

mkdir -p "$TARGET_HOME" "$LOCAL_BIN"

install -m 0755 "$ROOT/scripts/ubuntu/start-anland-plasma.sh" "$TARGET_HOME/start-anland-plasma.sh"
install -m 0755 "$ROOT/scripts/ubuntu/startplasma-anland.sh" "$TARGET_HOME/startplasma-anland.sh"
install -m 0755 "$ROOT/scripts/ubuntu/tablet-mode.sh" "$TARGET_HOME/tablet-mode.sh"
install -m 0755 "$ROOT/scripts/ubuntu/desktop-mode.sh" "$TARGET_HOME/desktop-mode.sh"
install -m 0755 "$ROOT/scripts/ubuntu/toggle-tablet-mode.sh" "$TARGET_HOME/toggle-tablet-mode.sh"
install -m 0755 "$ROOT/scripts/ubuntu/true-tablet-mode.sh" "$TARGET_HOME/true-tablet-mode.sh"
install -m 0644 "$ROOT/scripts/ubuntu/kwin-tablet-mode.py" "$TARGET_HOME/kwin-tablet-mode.py"

install -m 0755 "$ROOT/scripts/ubuntu/bin/plasma-desktop-mode" "$LOCAL_BIN/plasma-desktop-mode"
install -m 0755 "$ROOT/scripts/ubuntu/bin/plasma-touch-mode" "$LOCAL_BIN/plasma-touch-mode"
install -m 0755 "$ROOT/scripts/ubuntu/bin/plasma-toggle-mode" "$LOCAL_BIN/plasma-toggle-mode"

printf '%s\n' "Ubuntu/KDE helpers installed under $TARGET_HOME and $LOCAL_BIN."
