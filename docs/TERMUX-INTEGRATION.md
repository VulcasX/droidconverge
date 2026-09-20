# Termux integration

DroidConverge uses Termux as the Android-side user environment for starting Anland and entering the Ubuntu/chroot KDE session.

## Installed files

The repository keeps project-owned Termux files under `scripts/termux/`:

```text
scripts/termux/bin/start-ubuntu-kde.sh
scripts/termux/bin/startplasma-anland.sh
scripts/termux/bin/anland-bridge.sh
scripts/termux/bin/anland-haptic-test
scripts/termux/bin/droidconverge-session
scripts/termux/.shortcuts/tasks/Ubuntu-KDE
scripts/termux/.termux/tasker/haptic
```

The installer copies the `bin/` helpers into Termux `$PREFIX/bin` and the
launcher/Tasker entries into the active Termux home. It does not enable
external commands; see `docs/EXTERNAL-DISPLAY.md` for the optional panel setup.

## Start sequence

`start-ubuntu-kde.sh`:

1. starts Anland when it is not already running;
2. waits for the display daemon socket;
3. binds Termux temporary storage into the chroot `/tmp`;
4. calls the Ubuntu entry script;
5. unmounts the bind mount when the session ends.

## Anland environment

`startplasma-anland.sh` contains the current graphics/session environment used for the container session, including detection of KGSL and DRM, Anland socket selection, Wayland startup and optional PipeWire startup.

The script must be treated as hardware-dependent. Do not assume that a given `/dev/dri/renderD*`, KGSL node or GPU environment exists on another device.

## Haptic bridge helper

`anland-bridge.sh` is a local helper that can switch the Anland Termux application between touch and desktop modes and can issue a simple local vibration test. It is separate from the authenticated DroidConverge TCP protocol.

## Shortcuts and Tasker

The `.shortcuts` entry is a thin launcher for `start-ubuntu-kde.sh`.

The Tasker helper runs:

```bash
termux-vibrate -d 50
```

No real Bridge token is stored in these files.
