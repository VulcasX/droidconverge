#!/usr/bin/env bash

RED='\033[31m'
GREEN='\033[32m'
NC='\033[0m'

ANLAND_HAVE_KGSL=0
ANLAND_HAVE_DRM=0
ANLAND_PLASMA_DEBUG=${ANLAND_PLASMA_DEBUG:-1}

if [[ -r /dev/kgsl-3d0 ]]; then
    ANLAND_HAVE_KGSL=1
fi

if [[ -r /dev/dri/renderD128 ]]; then
    ANLAND_HAVE_DRM=1
fi

stop_plasma() {
    killall plasmashell > /dev/null 2>&1
    killall kwin_wayland > /dev/null 2>&1
    killall startplasma > /dev/null 2>&1
}

set_common_environment() {
    unset DISPLAY
    export QT_QPA_PLATFORM=wayland
    export XDG_CURRENT_DESKTOP=KDE
    export XDG_SESSION_DESKTOP=KDE
    export ANLAND=1

    unset ANLAND_NO_DRM_DEVICE ANLAND_DRM_DEVICE EGL_PLATFORM
    unset ANLAND_PIPEWIRE_UNRESTRICTED ANLAND_SOFTWARE_SESSION
    unset MESA_LOADER_DRIVER_OVERRIDE TURNIP_KMD GALLIUM_DRIVER
    unset FD_FORCE_KGSL XWAYLAND_FORCE_KGSL_SURFACELESS
}

enable_kgsl() {
    export MESA_LOADER_DRIVER_OVERRIDE=kgsl
    export TURNIP_KMD=kgsl
    export GALLIUM_DRIVER=freedreno
    export FD_FORCE_KGSL=1
    export XWAYLAND_FORCE_KGSL_SURFACELESS=1
}

show_starting_message() {
    printf '%b\n' "${GREEN}Starting KDE Plasma. Please switch to the \"Anland Termux\" app.${NC}"
}

run_plasma_command() {
    if [[ $ANLAND_PLASMA_DEBUG -eq 1 ]]; then
        "$@"
    else
        "$@" > /dev/null 2>&1
    fi
}

wait_for_socket() {
    local socket_path=$1
    local attempts=50

    while [[ ! -S $socket_path && $attempts -gt 0 ]]; do
        sleep 0.1
        ((attempts--))
    done

    [[ -S $socket_path ]]
}

process_matches_pipewire_runtime() {
    local proc_dir=$1
    local process_name=$2
    local process_comm entry
    local process_pipewire_runtime process_xdg_runtime

    [[ -r $proc_dir/comm && -r $proc_dir/environ ]] || return 1
    read -r process_comm < "$proc_dir/comm"
    [[ $process_comm == "$process_name" ]] || return 1

    while IFS= read -r -d '' entry; do
        case $entry in
            PIPEWIRE_RUNTIME_DIR=*) process_pipewire_runtime=${entry#*=} ;;
            XDG_RUNTIME_DIR=*) process_xdg_runtime=${entry#*=} ;;
        esac
    done < "$proc_dir/environ"

    [[ ${process_pipewire_runtime:-$process_xdg_runtime} == "$XDG_RUNTIME_DIR" ]]
}

process_uses_pipewire_runtime() {
    local process_name=$1
    local proc_dir

    for proc_dir in /proc/[0-9]*; do
        process_matches_pipewire_runtime "$proc_dir" "$process_name" && return 0
    done

    return 1
}

stop_audio_services() {
    local process_name proc_dir
    local attempts=20

    for process_name in pipewire-pulse wireplumber pipewire; do
        for proc_dir in /proc/[0-9]*; do
            if process_matches_pipewire_runtime "$proc_dir" "$process_name"; then
                kill "${proc_dir##*/}" > /dev/null 2>&1
            fi
        done
    done

    while [[ $attempts -gt 0 ]]; do
        if ! process_uses_pipewire_runtime pipewire-pulse &&
            ! process_uses_pipewire_runtime wireplumber &&
            ! process_uses_pipewire_runtime pipewire; then
            break
        fi
        sleep 0.1
        ((attempts--))
    done

    rm -f \
        "$XDG_RUNTIME_DIR/pipewire-0" \
        "$XDG_RUNTIME_DIR/pipewire-0.lock" \
        "$XDG_RUNTIME_DIR/anland-pulse/native"
}

start_audio_services() {
    local audio_log_dir=${ANLAND_SOCKET%/*}
    local pipewire_config_home="$XDG_RUNTIME_DIR/anland-pipewire-config"
    local command_name
    local -a pipewire_server_env=(env)
    local -a pipewire_client_env=(env)
    local -a wireplumber_env=(env)

    if [[ ${ANLAND_AUDIO_DEBUG:-0} -eq 1 ]]; then
        pipewire_server_env+=("PIPEWIRE_DEBUG=I,mod.protocol-native:T,conn.*:T")
        pipewire_client_env+=("PIPEWIRE_DEBUG=I,mod.protocol-pulse:T,conn.*:T")
        wireplumber_env+=("WIREPLUMBER_DEBUG=4")
    fi

    for command_name in pipewire wireplumber pipewire-pulse; do
        if ! command -v "$command_name" > /dev/null 2>&1; then
            printf '%b\n' "${RED}Audio disabled: missing ${command_name}. Install pipewire (Termux) or pipewire-audio (Debian/Ubuntu).${NC}" >&2
            return 0
        fi
    done

    export PIPEWIRE_RUNTIME_DIR="$XDG_RUNTIME_DIR"
    export PULSE_RUNTIME_PATH="$XDG_RUNTIME_DIR/anland-pulse"
    export PULSE_SERVER="unix:$PULSE_RUNTIME_PATH/native"
    mkdir -p "$audio_log_dir" "$PULSE_RUNTIME_PATH"

    if [[ ! -S $XDG_RUNTIME_DIR/pipewire-0 ]]; then
        if [[ ${ANLAND_PIPEWIRE_UNRESTRICTED:-0} -eq 1 ]]; then
            mkdir -p \
                "$pipewire_config_home/pipewire/pipewire.conf.d" \
                "$pipewire_config_home/wireplumber/wireplumber.conf.d"
            printf '%s\n' \
                'module.access.args = {' \
                '    access.socket = {' \
                '        pipewire-0 = "unrestricted"' \
                '        pipewire-0-manager = "unrestricted"' \
                '    }' \
                '}' \
                > "$pipewire_config_home/pipewire/pipewire.conf.d/99-anland-access.conf"
            printf '%s\n' \
                'access.rules = [' \
                '    {' \
                '        matches = [ { access = "flatpak" } ]' \
                '        actions = {' \
                '            update-props = {' \
                '                access = "unrestricted"' \
                '                default_permissions = "all"' \
                '            }' \
                '        }' \
                '    }' \
                ']' \
                > "$pipewire_config_home/wireplumber/wireplumber.conf.d/99-anland-access.conf"
            pipewire_server_env+=("XDG_CONFIG_HOME=$pipewire_config_home")
            wireplumber_env+=("XDG_CONFIG_HOME=$pipewire_config_home")
            "${pipewire_server_env[@]}" pipewire > "$audio_log_dir/pipewire.log" 2>&1 &
        else
            "${pipewire_server_env[@]}" pipewire > "$audio_log_dir/pipewire.log" 2>&1 &
        fi
        if ! wait_for_socket "$XDG_RUNTIME_DIR/pipewire-0"; then
            printf '%b\n' "${RED}Audio disabled: PipeWire failed to start. See $audio_log_dir/pipewire.log.${NC}" >&2
            return 0
        fi
    fi

    if ! process_uses_pipewire_runtime wireplumber; then
        "${wireplumber_env[@]}" wireplumber > "$audio_log_dir/wireplumber.log" 2>&1 &
    fi

    if [[ ! -S $PULSE_RUNTIME_PATH/native ]]; then
        "${pipewire_client_env[@]}" pipewire-pulse > "$audio_log_dir/pipewire-pulse.log" 2>&1 &
        if ! wait_for_socket "$PULSE_RUNTIME_PATH/native"; then
            printf '%b\n' "${RED}PulseAudio compatibility failed to start. See $audio_log_dir/pipewire-pulse.log.${NC}" >&2
        fi
    fi
}

start_termux_native() {
    if [[ $ANLAND_HAVE_KGSL -eq 0 ]]; then
        printf '%b\n' "${RED}Currently, running Anland: Termux in Termux Native on non-Snapdragon processors is not supported. Please try running it in a PRoot/Chroot/LXC container.${NC}" >&2
        return 1
    fi

    mkdir -p "$TMPDIR/run"
    chown -R "$(id -un):$(id -gn)" "$TMPDIR/run"
    chmod -R 700 "$TMPDIR/run"
    mkdir -p "$TMPDIR/.X11-unix"
    chmod 1777 "$TMPDIR/.X11-unix"

    killall anland > /dev/null 2>&1
    anland > /dev/null 2>&1 &
    stop_plasma

    set_common_environment
    export XDG_RUNTIME_DIR="$TMPDIR/run"
    export ANLAND_SOCKET="$TMPDIR/anland/display_daemon.sock"
    export ANLAND_NO_DRM_DEVICE=1
    export EGL_PLATFORM=surfaceless
    enable_kgsl
    start_audio_services

    rm -f "$XDG_RUNTIME_DIR"/wayland-* > /dev/null 2>&1
    show_starting_message
    run_plasma_command dbus-run-session startplasma-wayland
}

run_container_session() {
    trap stop_audio_services EXIT
    start_audio_services

    if [[ ${ANLAND_SOFTWARE_SESSION:-0} -eq 1 ]]; then
        kwin_wayland plasmashell > /dev/null 2>&1 &
        local desktop_pid=$!
        sleep 3
        konsole > /dev/null 2>&1
        wait "$desktop_pid"
    else
        startplasma-wayland
    fi
}

start_container() {
    sudo chmod -R 777 /tmp/anland
    stop_plasma
    set_common_environment
    export ANLAND_SOCKET=/tmp/anland/display_daemon.sock
    export ANLAND_PIPEWIRE_UNRESTRICTED=1

    if [[ $ANLAND_HAVE_DRM -eq 1 ]]; then
        export ANLAND_DRM_DEVICE=/dev/dri/renderD128
    else
        export ANLAND_NO_DRM_DEVICE=1
        export EGL_PLATFORM=surfaceless
    fi

    if [[ $ANLAND_HAVE_KGSL -eq 1 ]]; then
        enable_kgsl
    fi

    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
    sudo mkdir -p "$XDG_RUNTIME_DIR"
    sudo chown "$(id -un):$(id -gn)" "$XDG_RUNTIME_DIR"
    chmod 700 "$XDG_RUNTIME_DIR"
    stop_audio_services
    rm -f "$XDG_RUNTIME_DIR"/wayland-* > /dev/null 2>&1
    sudo mkdir -p /tmp/.X11-unix
    sudo chmod 1777 /tmp/.X11-unix

    show_starting_message
    if [[ $ANLAND_HAVE_DRM -eq 0 && $ANLAND_HAVE_KGSL -eq 0 ]]; then
        export ANLAND_SOFTWARE_SESSION=1
    else
        unset ANLAND_SOFTWARE_SESSION
    fi
    run_plasma_command dbus-run-session -- "$BASH" "${BASH_SOURCE[0]}" --container-session
}

if [[ ${1:-} == --container-session ]]; then
    run_container_session
elif [[ -n ${TERMUX_VERSION:-} ]]; then
    start_termux_native
else
    start_container
fi
