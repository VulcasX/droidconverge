# Plasma Mobile logout integration

DroidConverge provides an optional Plasma Mobile Quick Setting that opens
KDE's native Breeze Mobile logout greeter.

## Why this exists

In an Android chroot session there may be no usable systemd-logind session
backend. KDE session-management operations that depend on such a backend can
therefore be unavailable even though Plasma Mobile and the KDE logout greeter
itself are working.

DroidConverge does not emulate logind and does not modify Plasma Mobile's
system packages.

The integration instead launches KDE's installed
`ksmserver-logout-greeter` using the Breeze Mobile look-and-feel.

## Files

- `scripts/droidconverge-logout`
- `scripts/install-plasma-logout.sh`
- `plasma/quicksettings/org.droidconverge.quicksetting.logout/`

## Install

Run as the normal Linux desktop user, not as root:

    ./scripts/install-plasma-logout.sh

Then restart Plasma Shell or start a new Plasma Mobile session.

The installer:

- installs `droidconverge-logout` in `~/.local/bin`;
- installs the Quick Setting in the user's Plasma data directory;
- adds the Quick Setting ID to Plasma Mobile's enabled Quick Settings;
- avoids modifying distribution-owned Plasma files.

## Scope

This integration currently opens the KDE logout UI only.

Android power-button handling, host shutdown/reboot, and hardware-key
integration are intentionally outside the scope of this component.

## Command path

The Quick Setting source contains a command-path placeholder.

During installation DroidConverge replaces it with the absolute path to the
installed helper under the current user's `~/.local/bin`.

This is intentional: minimal Plasma Mobile/chroot sessions may not include
`~/.local/bin` in PlasmaShell's `PATH`.
