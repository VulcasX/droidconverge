#!/bin/bash

set -e

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/plasma-reset-backup-$STAMP"

mkdir -p "$BACKUP"

echo
echo "=============================================="
echo "        RESET PLASMA DESKTOP"
echo "=============================================="
echo
echo "Backup: $BACKUP"
echo

# ------------------------------------------------------------
# 1. Salva le configurazioni attuali
# ------------------------------------------------------------

for f in \
    "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" \
    "$HOME/.config/plasmashellrc" \
    "$HOME/.config/kwinrc"
do
    if [ -f "$f" ]; then
        cp -a "$f" "$BACKUP/"
        echo "[BACKUP] $f"
    fi
done

# ------------------------------------------------------------
# 2. Ferma Plasma Shell
# ------------------------------------------------------------

echo
echo "[1/5] Arresto plasmashell..."

kquitapp6 plasmashell 2>/dev/null || true

sleep 2

# ------------------------------------------------------------
# 3. Rimuove il layout Plasma personalizzato
# ------------------------------------------------------------

echo "[2/5] Reset layout pannelli/widget..."

if [ -f "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" ]; then
    mv \
        "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" \
        "$BACKUP/plasma-org.kde.plasma.desktop-appletsrc.removed"
fi

# ------------------------------------------------------------
# 4. Reset impostazioni specifiche introdotte da noi
# ------------------------------------------------------------

echo "[3/5] Ripristino KWin..."

# Virtual keyboard: comportamento predefinito
kwriteconfig6 \
    --file "$HOME/.config/kwinrc" \
    --group Wayland \
    --key InputMethod \
    ""

# Tablet Mode: comportamento automatico/predefinito
kwriteconfig6 \
    --file "$HOME/.config/kwinrc" \
    --group Input \
    --key TabletMode \
    "auto"

# ------------------------------------------------------------
# 5. Riavvia Plasma
# ------------------------------------------------------------

echo "[4/5] Avvio nuovo Plasma Shell..."

nohup plasmashell --replace \
    > "$HOME/plasmashell-reset.log" 2>&1 &

sleep 6

echo "[5/5] Controllo..."

if pgrep -x plasmashell >/dev/null; then
    echo
    echo "=============================================="
    echo "       RESET COMPLETATO"
    echo "=============================================="
    echo
    echo "Plasma Shell: OK"
    echo
    echo "Backup conservato in:"
    echo "$BACKUP"
    echo
else
    echo
    echo "ATTENZIONE: plasmashell non risulta attivo."
    echo "Log:"
    echo "$HOME/plasmashell-reset.log"
    exit 1
fi
