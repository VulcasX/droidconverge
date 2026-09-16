#!/data/data/com.termux/files/usr/bin/bash
set -eu
REPO_URL="${DROIDCONVERGE_REPO_URL:-https://github.com/VulcasX/droidconverge.git}"
DEST="${DROIDCONVERGE_INSTALL_DIR:-$HOME/.local/share/droidconverge}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
command -v git >/dev/null 2>&1 || { echo "ERROR: git is required." >&2; exit 1; }
git clone --depth 1 "$REPO_URL" "$TMP/repo" >/dev/null 2>&1
mkdir -p "$DEST" "$HOME/.shortcuts/tasks" "$HOME/.termux/tasker"
cp "$TMP/repo/scripts/termux/"*.sh "$DEST/" 2>/dev/null || true
cp "$TMP/repo/scripts/termux/anland-haptic-test" "$DEST/" 2>/dev/null || true
chmod +x "$DEST/"* 2>/dev/null || true
cp "$TMP/repo/scripts/termux/.shortcuts/tasks/Ubuntu-KDE" "$HOME/.shortcuts/tasks/Ubuntu-KDE" 2>/dev/null || true
cp "$TMP/repo/scripts/termux/.termux/tasker/haptic" "$HOME/.termux/tasker/haptic" 2>/dev/null || true
chmod +x "$HOME/.shortcuts/tasks/Ubuntu-KDE" "$HOME/.termux/tasker/haptic" 2>/dev/null || true
echo "DroidConverge Termux integration installed under $DEST"
