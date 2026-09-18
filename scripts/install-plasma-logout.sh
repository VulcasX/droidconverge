#!/usr/bin/env bash
set -euo pipefail

QS_ID="org.droidconverge.quicksetting.logout"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

BIN_DIR="${HOME}/.local/bin"
QS_ROOT="${HOME}/.local/share/plasma/quicksettings"
QS_DEST="${QS_ROOT}/${QS_ID}"

SOURCE_QML="$REPO_ROOT/plasma/quicksettings/$QS_ID/contents/ui/main.qml"
INSTALLED_COMMAND="$BIN_DIR/droidconverge-logout"

command -v kwriteconfig6 >/dev/null 2>&1 || {
    echo "DroidConverge: kwriteconfig6 is required." >&2
    exit 1
}

command -v kreadconfig6 >/dev/null 2>&1 || {
    echo "DroidConverge: kreadconfig6 is required." >&2
    exit 1
}

install -d "$BIN_DIR"
install -m 0755 \
    "$REPO_ROOT/scripts/droidconverge-logout" \
    "$INSTALLED_COMMAND"

install -d "$QS_DEST/contents/ui"

install -m 0644 \
    "$REPO_ROOT/plasma/quicksettings/$QS_ID/metadata.json" \
    "$QS_DEST/metadata.json"

# PlasmaShell's PATH does not necessarily include ~/.local/bin.
# Generate the installed QML with the user's absolute command path.
sed \
    "s|@DROIDCONVERGE_LOGOUT_COMMAND@|${INSTALLED_COMMAND}|g" \
    "$SOURCE_QML" \
    > "$QS_DEST/contents/ui/main.qml"

chmod 0644 "$QS_DEST/contents/ui/main.qml"

CURRENT="$(
    kreadconfig6 \
        --file plasmamobilerc \
        --group QuickSettings \
        --key enabledQuickSettings 2>/dev/null || true
)"

case ",${CURRENT}," in
    *",${QS_ID},"*)
        ;;
    *)
        NEW="${CURRENT:+${CURRENT},}${QS_ID}"

        kwriteconfig6 \
            --file plasmamobilerc \
            --group QuickSettings \
            --key enabledQuickSettings \
            "$NEW"
        ;;
esac

echo "DroidConverge Plasma Mobile logout quick setting installed."
echo "Command: $INSTALLED_COMMAND"
echo "Restart plasmashell to load it."
