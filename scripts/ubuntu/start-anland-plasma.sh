#!/usr/bin/env bash

set -u

export LANG=it_IT.UTF-8
export LANGUAGE=it_IT:it
export LC_ALL=it_IT.UTF-8

GPU="/dev/dri/renderD128"
SOCKET="/tmp/anland/display_daemon.sock"

echo "========================================"
echo " Ubuntu 26.04 KDE Plasma + Anland"
echo " User: $(id -un)"
echo "========================================"

if [ "$(id -u)" != "1000" ]; then
    echo "[ERRORE] KDE deve essere eseguito come utente android (UID 1000)."
    exit 1
fi

if [ ! -e "$GPU" ]; then
    echo "[ERRORE] $GPU non esiste."
    exit 1
fi

if [ ! -S "$SOCKET" ]; then
    echo "[ERRORE] Socket Anland non trovato: $SOCKET"
    exit 1
fi

export XDG_RUNTIME_DIR="/run/user/$(id -u)"

if [ ! -d "$XDG_RUNTIME_DIR" ]; then
    echo "[ERRORE] XDG_RUNTIME_DIR non esiste: $XDG_RUNTIME_DIR"
    exit 1
fi

if [ "$(stat -c '%u' "$XDG_RUNTIME_DIR")" != "$(id -u)" ]; then
    echo "[ERRORE] $XDG_RUNTIME_DIR non appartiene all'utente corrente."
    exit 1
fi

chmod 700 "$XDG_RUNTIME_DIR"

unset DISPLAY

export QT_QPA_PLATFORM=wayland
export XDG_CURRENT_DESKTOP=KDE
export XDG_SESSION_DESKTOP=KDE

export ANLAND_SOCKET="$SOCKET"
export ANLAND=1
export ANLAND_DRM_DEVICE="$GPU"

export MESA_LOADER_DRIVER_OVERRIDE=kgsl
export TURNIP_KMD=kgsl
export GALLIUM_DRIVER=freedreno
export FD_FORCE_KGSL=1
export XWAYLAND_FORCE_KGSL_SURFACELESS=1

export ANLAND_PIPEWIRE_UNRESTRICTED=1
export PIPEWIRE_RUNTIME_DIR="$XDG_RUNTIME_DIR"
export PULSE_RUNTIME_PATH="$XDG_RUNTIME_DIR/anland-pulse"
export PULSE_SERVER="unix:$PULSE_RUNTIME_PATH/native"

PIPEWIRE_CONFIG_HOME="$XDG_RUNTIME_DIR/anland-pipewire-config"
AUDIO_LOG_DIR="/tmp/anland"

wait_for_socket() {
    local socket_path="$1"
    local attempts=50

    while [ ! -S "$socket_path" ] && [ "$attempts" -gt 0 ]; do
        sleep 0.1
        attempts=$((attempts - 1))
    done

    [ -S "$socket_path" ]
}

process_matches_pipewire_runtime() {
    local proc_dir="$1"
    local process_name="$2"
    local process_comm=""
    local entry=""
    local process_pipewire_runtime=""
    local process_xdg_runtime=""

    [ -r "$proc_dir/comm" ] && [ -r "$proc_dir/environ" ] || return 1

    read -r process_comm < "$proc_dir/comm"
    [ "$process_comm" = "$process_name" ] || return 1

    while IFS= read -r -d '' entry; do
        case "$entry" in
            PIPEWIRE_RUNTIME_DIR=*)
                process_pipewire_runtime="${entry#*=}"
                ;;
            XDG_RUNTIME_DIR=*)
                process_xdg_runtime="${entry#*=}"
                ;;
        esac
    done < "$proc_dir/environ"

    [ "${process_pipewire_runtime:-$process_xdg_runtime}" = "$XDG_RUNTIME_DIR" ]
}

process_uses_pipewire_runtime() {
    local process_name="$1"
    local proc_dir

    for proc_dir in /proc/[0-9]*; do
        if process_matches_pipewire_runtime "$proc_dir" "$process_name"; then
            return 0
        fi
    done

    return 1
}

stop_audio_services() {
    local process_name
    local proc_dir
    local attempts=20

    echo "[AUDIO] Arresto eventuali servizi della sessione precedente..."

    for process_name in pipewire-pulse wireplumber pipewire; do
        for proc_dir in /proc/[0-9]*; do
            if process_matches_pipewire_runtime "$proc_dir" "$process_name"; then
                kill "${proc_dir##*/}" 2>/dev/null || true
            fi
        done
    done

    while [ "$attempts" -gt 0 ]; do
        if ! process_uses_pipewire_runtime pipewire-pulse &&
           ! process_uses_pipewire_runtime wireplumber &&
           ! process_uses_pipewire_runtime pipewire; then
            break
        fi

        sleep 0.1
        attempts=$((attempts - 1))
    done

    rm -f \
        "$XDG_RUNTIME_DIR/pipewire-0" \
        "$XDG_RUNTIME_DIR/pipewire-0.lock" \
        "$XDG_RUNTIME_DIR/pipewire-0-manager" \
        "$XDG_RUNTIME_DIR/pipewire-0-manager.lock" \
        "$PULSE_RUNTIME_PATH/native" \
        "$PULSE_RUNTIME_PATH/pid"
}

start_audio_services() {
    mkdir -p \
        "$AUDIO_LOG_DIR" \
        "$PULSE_RUNTIME_PATH" \
        "$PIPEWIRE_CONFIG_HOME/pipewire/pipewire.conf.d" \
        "$PIPEWIRE_CONFIG_HOME/wireplumber/wireplumber.conf.d"

    chmod 700 "$PULSE_RUNTIME_PATH"

    # Remove the obsolete DroidConverge WirePlumber fragment, if present.
    rm -f "$PIPEWIRE_CONFIG_HOME/wireplumber/51-anland-access.conf"

    cat > "$PIPEWIRE_CONFIG_HOME/pipewire/pipewire.conf.d/99-anland-access.conf" <<'PWCONF'
module.access.args = {
    access.socket = {
        pipewire-0 = "unrestricted"
        pipewire-0-manager = "unrestricted"
    }
}
PWCONF

    cat > "$PIPEWIRE_CONFIG_HOME/wireplumber/wireplumber.conf.d/99-anland-access.conf" <<'WPCONF'
access.rules = [
    {
        matches = [ { access = "flatpak" } ]
        actions = {
            update-props = {
                access = "unrestricted"
                default_permissions = "all"
            }
        }
    }
]
WPCONF

    echo "[AUDIO] Avvio PipeWire..."

    XDG_CONFIG_HOME="$PIPEWIRE_CONFIG_HOME" \
        pipewire >"$AUDIO_LOG_DIR/pipewire.log" 2>&1 &

    if ! wait_for_socket "$XDG_RUNTIME_DIR/pipewire-0"; then
        echo "[ERRORE] PipeWire non ha creato pipewire-0."
        tail -100 "$AUDIO_LOG_DIR/pipewire.log" 2>/dev/null
        return 1
    fi

    echo "[AUDIO] Avvio WirePlumber..."

    XDG_CONFIG_HOME="$PIPEWIRE_CONFIG_HOME" \
        wireplumber >"$AUDIO_LOG_DIR/wireplumber.log" 2>&1 &

    sleep 1

    echo "[AUDIO] Avvio pipewire-pulse..."

    XDG_CONFIG_HOME="$PIPEWIRE_CONFIG_HOME" \
        pipewire-pulse >"$AUDIO_LOG_DIR/pipewire-pulse.log" 2>&1 &

    if ! wait_for_socket "$PULSE_RUNTIME_PATH/native"; then
        echo "[ERRORE] pipewire-pulse non ha creato il socket Pulse."
        tail -100 "$AUDIO_LOG_DIR/pipewire-pulse.log" 2>/dev/null
        return 1
    fi

    echo "[OK] Stack audio Anland avviato."
}

cleanup() {
    stop_audio_services
}

trap cleanup EXIT HUP INT TERM

stop_audio_services

rm -f "$XDG_RUNTIME_DIR"/wayland-* 2>/dev/null || true

mkdir -p /tmp/.X11-unix 2>/dev/null || true
chmod 1777 /tmp/.X11-unix 2>/dev/null || true

start_audio_services || exit 1

echo
echo "----------------------------------------"
echo " Verifica audio"
echo "----------------------------------------"

printf 'PipeWire:      '
pgrep -c -u "$(id -u)" -x pipewire || true

printf 'WirePlumber:   '
pgrep -c -u "$(id -u)" -x wireplumber || true

printf 'pipewire-pulse:'
pgrep -c -u "$(id -u)" -x pipewire-pulse || true

timeout 5 wpctl status || {
    echo "[ERRORE] wpctl non risponde."
    exit 1
}

PULSE_SERVER="$PULSE_SERVER" \
    timeout 5 pactl info >/dev/null || {
        echo "[ERRORE] pactl non risponde."
        exit 1
    }

echo
echo "[OK] PipeWire / WirePlumber / Pulse funzionanti."
echo
echo "----------------------------------------"
echo " Avvio KDE Plasma"
echo "----------------------------------------"
echo

dbus-run-session startplasma-wayland
