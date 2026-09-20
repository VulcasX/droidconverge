#!/data/data/com.termux/files/usr/bin/bash
# Interactive, resumable installer. Run only in Termux on the target device.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DISTRO=ubuntu26
CHROOT=/data/local/chroot-distro/$DISTRO
STATE="$HOME/.local/state/droidconverge"
mode="${1:---check}"
[[ "$mode" == --check || "$mode" == --apply || "$mode" == --update ]] || { echo 'Usage: install-system.sh [--check|--apply|--update]' >&2; exit 2; }
[[ "${PREFIX:-}" == /data/data/com.termux/files/usr ]] || { echo 'Run inside the GitHub Termux app.' >&2; exit 1; }
[[ "$(uname -m)" == aarch64 ]] || { echo 'This installer requires ARM64.' >&2; exit 1; }
command -v su >/dev/null || { echo 'Root (su) is required for a real chroot.' >&2; exit 1; }
su -c 'id -u' 2>/dev/null | grep -qx 0 || { echo 'Root permission was not granted.' >&2; exit 1; }
command -v chroot-distro >/dev/null || { echo 'Install the reviewed chroot-distro Magisk module first; see docs/INSTALLATION.md.' >&2; exit 1; }
command -v anland >/dev/null || { echo 'Install the matching Anland Android app and Termux package first; see docs/INSTALLATION.md.' >&2; exit 1; }
[[ -d "$CHROOT" ]] || { echo "Missing $CHROOT. Create the Ubuntu 26.04 chroot with the reviewed chroot-distro procedure in docs/INSTALLATION.md." >&2; exit 1; }
[[ -f "$CHROOT/etc/os-release" ]] || { echo 'Chroot has no os-release; refusing to modify it.' >&2; exit 1; }
grep -q '^ID=ubuntu$' "$CHROOT/etc/os-release" || { echo 'Chroot is not Ubuntu.' >&2; exit 1; }
grep -Eq '^VERSION_ID="?26\.04"?$' "$CHROOT/etc/os-release" || { echo 'This setup requires Ubuntu 26.04.' >&2; exit 1; }
echo "Preflight OK: $DISTRO exists, root and Anland available."
[[ "$mode" != --check ]] || exit 0

if [[ "$mode" == --update ]]; then
    [[ -d "$ROOT/.git" ]] || { echo 'Update requires a Git checkout.' >&2; exit 1; }
    [[ -z "$(git -C "$ROOT" status --porcelain)" ]] || { echo 'Checkout has local changes; update refused.' >&2; exit 1; }
    git -C "$ROOT" pull --ff-only
fi

read -r -p 'Linux username (letters/numbers/underscore, starts with a letter): ' linux_user
[[ "$linux_user" =~ ^[a-z][a-z0-9_]{0,31}$ ]] || { echo 'Invalid username.' >&2; exit 1; }
read -r -p 'Install optional Firefox and useful desktop utilities? [y/N] ' optional
case "$optional" in y|Y|yes|YES) optional=yes ;; *) optional=no ;; esac
echo "Plan: back up existing project helpers; install repository helpers; create/check $linux_user; install KDE packages only when explicitly confirmed."
read -r -p 'Apply this plan? [y/N] ' approval
[[ "$approval" =~ ^(y|Y|yes|YES)$ ]] || { echo 'Cancelled without changes.'; exit 0; }

mkdir -p "$STATE"
backup="$STATE/installer-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup"
bash "$ROOT/scripts/install/install-termux.sh"

# Keep all privileged Ubuntu operations in one audited script copied into the
# chroot. No password is accepted by this script or stored in project state.
su -c "mkdir -p '$CHROOT/root/droidconverge-source/scripts'"
su -c "cp -r '$ROOT/scripts/install' '$ROOT/scripts/ubuntu' '$CHROOT/root/droidconverge-source/scripts/'"
su -c "cp '$ROOT/scripts/droidconverge-logout' '$ROOT/scripts/install-plasma-logout.sh' '$CHROOT/root/droidconverge-source/scripts/'"
su -c "cp -r '$ROOT/plasma' '$CHROOT/root/droidconverge-source/'"
su -c "chmod 700 '$CHROOT/root/droidconverge-source/scripts/install/setup-ubuntu-system.sh'"
su -c "chroot-distro command '$DISTRO' /bin/bash /root/droidconverge-source/scripts/install/setup-ubuntu-system.sh '$linux_user' '$optional'"
read -r -p 'Set the Linux account password now? [y/N] ' set_password
if [[ "$set_password" =~ ^(y|Y|yes|YES)$ ]]; then
    su -c "chroot-distro command '$DISTRO' /usr/bin/passwd '$linux_user'"
fi
echo 'Setup completed. Verify start-ubuntu-kde.sh and the Android display route before relying on the system.'
echo 'For rollback, restore Termux helpers from the backup path printed by install-termux.sh. Existing custom root launchers are left intact.'
