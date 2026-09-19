#!/bin/bash
# Experimental official Box64/Box32 Steam path for ARM64. No third-party installer is downloaded.
set -euo pipefail
mode=${1:---check}
[[ $mode == --check || $mode == --install ]] || { echo 'Usage: install-steam-arm64.sh [--check|--install]' >&2; exit 2; }
[[ $(uname -m) == aarch64 ]] || { echo 'ARM64 required.' >&2; exit 1; }
printf 'box64=%s\n' "$(command -v box64 || echo missing)"
printf 'steam=%s\n' "$(command -v steam || echo missing)"
[[ $mode == --install ]] || exit 0
[[ $(id -u) == 0 ]] || { echo 'Run --install as root inside the chroot.' >&2; exit 1; }
[[ -n ${DROIDCONVERGE_BOX64_REF:-} ]] || { echo 'Set DROIDCONVERGE_BOX64_REF to a reviewed Box64 tag or commit.' >&2; exit 1; }
apt-get update
apt-get install -y --no-install-recommends git ca-certificates curl cmake make gcc g++ python3 python3-apt binfmt-support
work=/usr/local/src/droidconverge-box64
if [[ -e $work ]]; then echo "$work already exists; refusing to overwrite." >&2; exit 1; fi
git init "$work"
git -C "$work" remote add origin https://github.com/ptitSeb/box64.git
git -C "$work" fetch --depth 1 origin "$DROIDCONVERGE_BOX64_REF"
git -C "$work" checkout --detach FETCH_HEAD
cmake -S "$work" -B "$work/build" -DARM64=1 -DBOX32=1 -DBOX32_BINFMT=1 -DBAD_SIGNAL=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build "$work/build" -j"$(nproc)"
cmake --install "$work/build"
ldconfig
desktop_user=${SUDO_USER:-android}
runuser -u "$desktop_user" -- /bin/bash "$work/install_steam.sh"
desktop_home=$(getent passwd "$desktop_user" | cut -d: -f6)
steam_entry="$desktop_home/steam/steam"
[[ -x $steam_entry ]] || { echo "Steam payload missing at $steam_entry." >&2; exit 1; }
cat >/usr/local/bin/steam <<EOF
#!/bin/sh
exec /usr/local/bin/box64 /usr/local/bin/box64-bash "$steam_entry" "\$@"
EOF
chmod 755 /usr/local/bin/steam
install -d -o "$desktop_user" -g "$desktop_user" "$desktop_home/.local/share/applications"
if [[ -f $desktop_home/steam/share/applications/steam.desktop ]]; then
  install -o "$desktop_user" -g "$desktop_user" -m 644 \
    "$desktop_home/steam/share/applications/steam.desktop" \
    "$desktop_home/.local/share/applications/steam.desktop"
fi
echo 'Steam files installed through the upstream Box64 script. Launch as the desktop user with: steam'
echo "Rollback: remove the Steam user directories after backing up games, then run '$work/uninstall.sh' if supplied; remove $work only after review."
