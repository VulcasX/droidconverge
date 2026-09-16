#!/data/data/com.termux/files/usr/bin/bash

DISTRO="ubuntu26"
CHROOT="/data/local/chroot-distro/$DISTRO"
TERMUX_TMP="$PREFIX/tmp"
CHROOT_TMP="$CHROOT/tmp"

echo "========================================"
echo " Ubuntu 26.04 + KDE Plasma + Anland"
echo "========================================"

# ----------------------------------------
# 1. Avvio Anland
# ----------------------------------------

echo "[1/4] Avvio Anland..."

if ! pgrep -x anland >/dev/null 2>&1; then
    echo "      Avvio Anland..."
    anland >/dev/null 2>&1 &
else
    echo "      Anland già in esecuzione."
fi

echo "      Attendo il socket Anland..."

for i in $(seq 1 30); do
    if [ -S "$TERMUX_TMP/anland/display_daemon.sock" ]; then
        echo "      Socket Anland OK."
        break
    fi
    sleep 1
done

if [ ! -S "$TERMUX_TMP/anland/display_daemon.sock" ]; then
    echo "[ERRORE] Socket Anland non trovato."
    exit 1
fi

# ----------------------------------------
# 2. Bind /tmp Termux -> chroot
# ----------------------------------------

echo "[2/4] Configurazione /tmp..."

if mountpoint -q "$CHROOT_TMP" 2>/dev/null; then
    echo "      /tmp è già collegato."
else
    echo "      Eseguo bind mount..."

    su -c "mount --bind '$TERMUX_TMP' '$CHROOT_TMP'"

    if [ $? -ne 0 ]; then
        echo "[ERRORE] Impossibile eseguire il bind mount."
        exit 1
    fi
fi

if [ -S "$CHROOT_TMP/anland/display_daemon.sock" ]; then
    echo "      Socket visibile nel chroot."
else
    echo "[ERRORE] Socket Anland non visibile nel chroot."
    su -c "umount '$CHROOT_TMP'" 2>/dev/null
    exit 1
fi

# ----------------------------------------
# 3. Avvio KDE
# ----------------------------------------

echo "[3/4] Avvio Ubuntu $DISTRO..."
echo
echo "----------------------------------------"
echo " Entrata nel chroot"
echo "----------------------------------------"
echo

su -c "chroot-distro command '$DISTRO' /root/start-kde-as-android.sh"

EXIT_CODE=$?

echo
echo "----------------------------------------"
echo " Sessione KDE terminata"
echo "----------------------------------------"

# ----------------------------------------
# 4. Pulizia
# ----------------------------------------

echo "[4/4] Pulizia..."

if mountpoint -q "$CHROOT_TMP" 2>/dev/null; then
    su -c "umount '$CHROOT_TMP'" 2>/dev/null
fi

echo
echo "Ubuntu KDE terminato."
echo "Exit code: $EXIT_CODE"

exit $EXIT_CODE
