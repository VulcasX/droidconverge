#!/bin/bash
set -euo pipefail
[[ "$(id -u)" == 0 ]] || { echo 'Run as root inside the chroot.' >&2; exit 1; }
linux_user="${1:?username required}"
optional="${2:-no}"
[[ "$linux_user" =~ ^[a-z][a-z0-9_]{0,31}$ ]] || exit 2
grep -q '^ID=ubuntu$' /etc/os-release || exit 1
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends dbus-user-session plasma-workspace plasma-desktop kwin-wayland pipewire pipewire-pulse wireplumber xwayland sudo
if [[ "$optional" == yes ]]; then
    apt-get install -y --no-install-recommends vim dolphin konsole
    bash /root/droidconverge-source/scripts/install/install-desktop-software.sh
    if apt-cache show firefox-esr >/dev/null 2>&1; then
        apt-get install -y --no-install-recommends firefox-esr
    elif apt-cache show firefox 2>/dev/null | grep -Eiq 'snap|transitional'; then
        echo 'Firefox in this Ubuntu repository requires Snap; chroot installation skipped. Choose a reviewed browser source manually.' >&2
    elif apt-cache show firefox >/dev/null 2>&1; then
        apt-get install -y --no-install-recommends firefox
    else
        echo 'Firefox package unavailable; install a reviewed browser source manually.' >&2
    fi
fi
if ! id "$linux_user" >/dev/null 2>&1; then
    if getent passwd 1000 >/dev/null; then
        echo 'UID 1000 is already used. Choose that existing account or resolve the conflict manually.' >&2
        exit 1
    fi
    useradd -m -u 1000 -s /bin/bash "$linux_user"
fi
uid="$(id -u "$linux_user")"
[[ "$uid" == 1000 ]] || { echo 'The Anland launcher currently requires UID 1000.' >&2; exit 1; }
install -d -m 0700 -o "$uid" -g "$linux_user" "/run/user/$uid"
install -d -m 0755 -o "$uid" -g "$linux_user" "/home/$linux_user/.local/bin"
export DROIDCONVERGE_TARGET_HOME="/home/$linux_user"
export DROIDCONVERGE_LOCAL_BIN="/home/$linux_user/.local/bin"
bash /root/droidconverge-source/scripts/install/install-ubuntu.sh
chown -R "$linux_user:$linux_user" "/home/$linux_user/.local" "/home/$linux_user"/*.sh "/home/$linux_user"/*.py
user_source="/home/$linux_user/.local/share/droidconverge-source"
install -d -m 0755 -o "$uid" -g "$linux_user" "$user_source/scripts"
cp /root/droidconverge-source/scripts/droidconverge-logout /root/droidconverge-source/scripts/install-plasma-logout.sh "$user_source/scripts/"
cp -r /root/droidconverge-source/plasma "$user_source/"
chown -R "$linux_user:$linux_user" "$user_source"
runuser -u "$linux_user" -- /bin/bash "$user_source/scripts/install-plasma-logout.sh"
if [[ ! -e /root/start-kde-as-android.sh ]]; then
    printf '#!/bin/sh\nexec runuser -u %s -- /home/%s/start-anland-plasma.sh\n' "$linux_user" "$linux_user" >/root/start-kde-as-android.sh
    chmod 700 /root/start-kde-as-android.sh
fi
echo "Linux user $linux_user exists. Set its password manually with passwd $linux_user."
