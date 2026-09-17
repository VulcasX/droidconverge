# Anland / PipeWire audio troubleshooting

## Firefox / YouTube hangs caused by stale audio services

A validated DroidConverge failure mode was caused by stale and duplicated PipeWire session services across repeated Anland/KDE starts.

### Symptoms

- YouTube remained on the loading spinner.
- Firefox `about:support` could hang.
- `wpctl status` could hang.
- `pactl info` could hang.
- Multiple WirePlumber processes could remain active.
- PipeWire could report an existing `pipewire-0.lock`.
- pipewire-pulse could find the Anland Pulse socket already in use.

The symptoms initially resembled a Firefox codec or Mesa/Freedreno/KGSL problem. Diagnostics confirmed that Firefox could decode media frames and that the accelerated graphics stack remained active.

## Root cause

The previous startup path could start `pipewire`, `wireplumber`, and `pipewire-pulse` again without first cleaning up services left by the previous Anland/KDE session.

This could leave multiple WirePlumber processes sharing the same PipeWire runtime and place the multimedia graph in an inconsistent state.

## Fix

`start-anland-plasma.sh` now manages the audio stack as part of the Anland session lifecycle:

- identify audio processes associated with the current XDG/PipeWire runtime;
- stop stale pipewire-pulse, WirePlumber, and PipeWire instances;
- wait for those processes to terminate;
- remove stale PipeWire locks and Pulse compatibility sockets;
- use the current WirePlumber `wireplumber.conf.d` configuration layout;
- start PipeWire, WirePlumber, and pipewire-pulse in a clean runtime;
- verify `wpctl` and `pactl` before Plasma starts;
- clean up the session audio services when Plasma exits.

Cleanup is scoped to the matching runtime instead of indiscriminately terminating unrelated audio processes.

## Validation

After a complete normal DroidConverge/Anland/KDE restart, the reference environment was validated with:

- exactly one PipeWire process;
- exactly one WirePlumber process;
- exactly one pipewire-pulse process;
- working `wpctl status`;
- working `pactl info`;
- the Anland remote speaker and microphone visible;
- Firefox YouTube video and audio playback working;
- Firefox `about:support` opening normally;
- subsequent video playback continuing to work.

## Diagnostics

```bash
pgrep -a pipewire
pgrep -a wireplumber
pgrep -a pipewire-pulse
timeout 5 wpctl status
PULSE_SERVER=unix:/run/user/1000/anland-pulse/native timeout 5 pactl info
```

Warnings related to RTKit, system D-Bus, snapd, V4L2, or libcamera may occur in the chroot environment and were not the cause of this validated failure.
