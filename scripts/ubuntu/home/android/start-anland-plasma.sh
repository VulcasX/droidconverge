#!/bin/bash

export LANG=it_IT.UTF-8
export LANGUAGE=it_IT:it
export LC_ALL=it_IT.UTF-8

echo "========================================"
echo " Ubuntu 26.04 KDE Plasma + Anland"
echo " User: $(id -un)"
echo "========================================"

# ----------------------------------------
# Controlli
# ----------------------------------------

if [ "$(id -u)" != "1000" ]; then
    echo "[ERRORE] KDE deve essere eseguito come utente android (UID 1000)."
    exit 1
fi

GPU="/dev/dri/renderD128"
SOCKET="/tmp/anland/display_daemon.sock"

if [ -e "$GPU" ]; then
    echo "[OK] GPU DRM:"
    ls -l "$GPU"
else
    echo "[ERRORE] $GPU non esiste."
    exit 1
fi

if [ -S "$SOCKET" ]; then
    echo "[OK] Socket Anland:"
    ls -l "$SOCKET"
else
    echo "[ERRORE] Socket Anland non trovato:"
    echo "        $SOCKET"
    exit 1
fi

# ----------------------------------------
# Runtime directory
# ----------------------------------------

export XDG_RUNTIME_DIR="/run/user/$(id -u)"

if [ ! -d "$XDG_RUNTIME_DIR" ]; then
    echo "[ERRORE] XDG_RUNTIME_DIR non esiste:"
    echo "        $XDG_RUNTIME_DIR"
    exit 1
fi

if [ "$(stat -c '%u' "$XDG_RUNTIME_DIR")" != "$(id -u)" ]; then
    echo "[ERRORE] $XDG_RUNTIME_DIR non appartiene all'utente corrente."
    ls -ld "$XDG_RUNTIME_DIR"
    exit 1
fi

chmod 700 "$XDG_RUNTIME_DIR"

# ----------------------------------------
# Ambiente Wayland / Anland
# ----------------------------------------

unset DISPLAY

export QT_QPA_PLATFORM=wayland
export XDG_CURRENT_DESKTOP=KDE
export XDG_SESSION_DESKTOP=KDE

export ANLAND_SOCKET="$SOCKET"
export ANLAND=1
export ANLAND_DRM_DEVICE="$GPU"

# ----------------------------------------
# Mesa / Freedreno / KGSL
# ----------------------------------------

export MESA_LOADER_DRIVER_OVERRIDE=kgsl
export TURNIP_KMD=kgsl
export GALLIUM_DRIVER=freedreno
export FD_FORCE_KGSL=1
export XWAYLAND_FORCE_KGSL_SURFACELESS=1

# ----------------------------------------
# PipeWire / Anland
# ----------------------------------------

export ANLAND_PIPEWIRE_UNRESTRICTED=1

# PipeWire deve utilizzare il runtime della sessione
export PIPEWIRE_RUNTIME_DIR="$XDG_RUNTIME_DIR"

# PulseAudio compatibility socket dedicato ad Anland
export PULSE_RUNTIME_PATH="$XDG_RUNTIME_DIR/anland-pulse"
export PULSE_SERVER="unix:$PULSE_RUNTIME_PATH/native"

mkdir -p "$PULSE_RUNTIME_PATH"
chmod 700 "$PULSE_RUNTIME_PATH"

# ----------------------------------------
# Configurazione PipeWire specifica Anland
# ----------------------------------------

PIPEWIRE_CONFIG_HOME="$XDG_RUNTIME_DIR/anland-pipewire-config"

mkdir -p \
    "$PIPEWIRE_CONFIG_HOME/pipewire/pipewire.conf.d" \
    "$PIPEWIRE_CONFIG_HOME/wireplumber"

cat > "$PIPEWIRE_CONFIG_HOME/pipewire/pipewire.conf.d/99-anland-access.conf" <<'PIPEWIRE_CONF'
module.access.args = {
    access.socket = {
        pipewire-0 = "unrestricted"
        pipewire-0-manager = "unrestricted"
    }
}
PIPEWIRE_CONF

cat > "$PIPEWIRE_CONFIG_HOME/wireplumber/51-anland-access.conf" <<'WIREPLUMBER_CONF'
access.rules = [
    {
        matches = [
            { access = "flatpak" }
        ]
        actions = {
            update-props = {
                access = "unrestricted"
                default_permissions = "all"
            }
        }
    }
]
WIREPLUMBER_CONF

# ----------------------------------------
# Pulizia vecchi socket Wayland
# ----------------------------------------

rm -f "$XDG_RUNTIME_DIR"/wayland-* 2>/dev/null

# ----------------------------------------
# X11
# ----------------------------------------

mkdir -p /tmp/.X11-unix 2>/dev/null || true
chmod 1777 /tmp/.X11-unix 2>/dev/null || true

# ----------------------------------------
# Informazioni
# ----------------------------------------

echo
echo "----------------------------------------"
echo "Configurazione"
echo "----------------------------------------"
echo "USER=$USER"
echo "UID=$(id -u)"
echo "GID=$(id -g)"
echo "GPU=$(cat /sys/class/kgsl/kgsl-3d0/gpu_model 2>/dev/null || echo unknown)"
echo "ANLAND_SOCKET=$ANLAND_SOCKET"
echo "ANLAND_DRM_DEVICE=$ANLAND_DRM_DEVICE"
echo "MESA_LOADER_DRIVER_OVERRIDE=$MESA_LOADER_DRIVER_OVERRIDE"
echo "GALLIUM_DRIVER=$GALLIUM_DRIVER"
echo "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"
echo "PIPEWIRE_RUNTIME_DIR=$PIPEWIRE_RUNTIME_DIR"
echo "PULSE_RUNTIME_PATH=$PULSE_RUNTIME_PATH"
echo "PULSE_SERVER=$PULSE_SERVER"
echo "ANLAND_PIPEWIRE_UNRESTRICTED=$ANLAND_PIPEWIRE_UNRESTRICTED"
echo

# ----------------------------------------
# Avvio PipeWire
# ----------------------------------------

echo "----------------------------------------"
echo "Avvio PipeWire"
echo "----------------------------------------"
echo

XDG_CONFIG_HOME="$PIPEWIRE_CONFIG_HOME" \
    pipewire >/tmp/pipewire.log 2>&1 &

PIPEWIRE_PID=$!

echo "PipeWire PID: $PIPEWIRE_PID"

for i in $(seq 1 20); do
    if [ -S "$XDG_RUNTIME_DIR/pipewire-0" ]; then
        echo "[OK] Socket PipeWire disponibile."
        break
    fi
    sleep 1
done

if [ ! -S "$XDG_RUNTIME_DIR/pipewire-0" ]; then
    echo "[ERRORE] Socket PipeWire non trovato."
    cat /tmp/pipewire.log 2>/dev/null
    exit 1
fi

# ----------------------------------------
# Avvio WirePlumber
# ----------------------------------------

echo
echo "----------------------------------------"
echo "Avvio WirePlumber"
echo "----------------------------------------"
echo

XDG_CONFIG_HOME="$PIPEWIRE_CONFIG_HOME" \
    wireplumber >/tmp/wireplumber.log 2>&1 &

WIREPLUMBER_PID=$!

echo "WirePlumber PID: $WIREPLUMBER_PID"

sleep 2

# ----------------------------------------
# Avvio pipewire-pulse
# ----------------------------------------

echo
echo "----------------------------------------"
echo "Avvio pipewire-pulse"
echo "----------------------------------------"
echo

XDG_CONFIG_HOME="$PIPEWIRE_CONFIG_HOME" \
    pipewire-pulse >/tmp/pipewire-pulse.log 2>&1 &

PIPEWIRE_PULSE_PID=$!

echo "pipewire-pulse PID: $PIPEWIRE_PULSE_PID"

for i in $(seq 1 20); do
    if [ -S "$PULSE_RUNTIME_PATH/native" ]; then
        echo "[OK] Socket PulseAudio disponibile."
        break
    fi
    sleep 1
done

if [ ! -S "$PULSE_RUNTIME_PATH/native" ]; then
    echo "[ERRORE] Socket PulseAudio non trovato."
    echo
    echo "----- pipewire.log -----"
    cat /tmp/pipewire.log 2>/dev/null
    echo
    echo "----- wireplumber.log -----"
    cat /tmp/wireplumber.log 2>/dev/null
    echo
    echo "----- pipewire-pulse.log -----"
    cat /tmp/pipewire-pulse.log 2>/dev/null
    exit 1
fi

# ----------------------------------------
# Controllo audio
# ----------------------------------------

echo
echo "----------------------------------------"
echo "Stato audio"
echo "----------------------------------------"
echo

pgrep -a pipewire || true
pgrep -a wireplumber || true

echo
echo "Sink:"
PULSE_SERVER="$PULSE_SERVER" pactl list short sinks 2>/dev/null || true

echo
echo "----------------------------------------"
echo "Avvio KDE Plasma"
echo "----------------------------------------"
echo

exec dbus-run-session startplasma-wayland
