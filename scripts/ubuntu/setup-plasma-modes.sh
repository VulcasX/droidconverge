#!/bin/bash

set -e

BASE="$HOME/.local/share/plasma-modes"
BIN="$HOME/.local/bin"
APPS="$HOME/.local/share/applications"

mkdir -p "$BASE" "$BIN" "$APPS"

# ============================================================
# PLASMA TOUCH MODE
# ============================================================

cat > "$BIN/plasma-touch-mode" <<'SCRIPT'
#!/bin/bash

set -e

LOG="$HOME/.local/share/plasma-modes/plasma-mobile.log"

pkill -x plasmashell 2>/dev/null || true
sleep 1

nohup plasmashell --replace -p org.kde.plasma.mobileshell \
    >"$LOG" 2>&1 &

disown

echo "Plasma Touch attivato."
SCRIPT

chmod +x "$BIN/plasma-touch-mode"


# ============================================================
# PLASMA DESKTOP MODE
# ============================================================

cat > "$BIN/plasma-desktop-mode" <<'SCRIPT'
#!/bin/bash

set -e

LOG="$HOME/.local/share/plasma-modes/plasma-desktop.log"

pkill -x plasmashell 2>/dev/null || true
sleep 1

nohup plasmashell --replace -p org.kde.plasma.desktop \
    >"$LOG" 2>&1 &

disown

echo "Plasma Desktop attivato."
SCRIPT

chmod +x "$BIN/plasma-desktop-mode"


# ============================================================
# TOGGLE AUTOMATICO
# ============================================================

cat > "$BIN/plasma-toggle-mode" <<'SCRIPT'
#!/bin/bash

if pgrep -af 'plasmashell.*org.kde.plasma.mobileshell' >/dev/null; then
    "$HOME/.local/bin/plasma-desktop-mode"
else
    "$HOME/.local/bin/plasma-touch-mode"
fi
SCRIPT

chmod +x "$BIN/plasma-toggle-mode"


# ============================================================
# LAUNCHER - TOUCH
# ============================================================

cat > "$APPS/plasma-touch-mode.desktop" <<EOF2
[Desktop Entry]
Name=Plasma Touch
GenericName=Modalità Touch
Comment=Passa a Plasma Mobile
Exec=$BIN/plasma-touch-mode
Icon=phone
Terminal=false
Type=Application
Categories=Settings;System;
StartupNotify=false
EOF2


# ============================================================
# LAUNCHER - DESKTOP
# ============================================================

cat > "$APPS/plasma-desktop-mode.desktop" <<EOF2
[Desktop Entry]
Name=Plasma Desktop
GenericName=Modalità Desktop
Comment=Passa alla shell KDE Desktop
Exec=$BIN/plasma-desktop-mode
Icon=computer
Terminal=false
Type=Application
Categories=Settings;System;
StartupNotify=false
EOF2


# ============================================================
# LAUNCHER - TOGGLE
# ============================================================

cat > "$APPS/plasma-toggle-mode.desktop" <<EOF2
[Desktop Entry]
Name=Cambia modalità Plasma
GenericName=Touch / Desktop
Comment=Passa automaticamente tra Plasma Mobile e Plasma Desktop
Exec=$BIN/plasma-toggle-mode
Icon=preferences-desktop
Terminal=false
Type=Application
Categories=Settings;System;
StartupNotify=false
EOF2


# ============================================================
# INSTALLAZIONE APPLICAZIONI KDE UTILI
# ============================================================

echo
echo "=== INSTALLAZIONE APPLICAZIONI KDE ==="

sudo apt-get install -y \
    dolphin \
    ark \
    kate \
    spectacle \
    filelight \
    kdeconnect \
    plasma-systemmonitor \
    konsole \
    systemsettings


# ============================================================
# AGGIORNAMENTO DATABASE APPLICAZIONI
# ============================================================

update-desktop-database "$APPS" 2>/dev/null || true


# ============================================================
# REPORT
# ============================================================

echo
echo "============================================"
echo "   PLASMA MODES CONFIGURATI CORRETTAMENTE"
echo "============================================"
echo
echo "Touch:"
echo "  $BIN/plasma-touch-mode"
echo
echo "Desktop:"
echo "  $BIN/plasma-desktop-mode"
echo
echo "Toggle:"
echo "  $BIN/plasma-toggle-mode"
echo
echo "Launcher creati in:"
echo "  $APPS"
echo
echo "KWin NON è stato modificato."
echo "Mesa/Turnip NON sono stati modificati."
echo "============================================"
