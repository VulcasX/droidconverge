# Desktop and Touch modes

DroidConverge currently provides two separate working Plasma modes.

## Desktop Mode

Purpose: use the touchscreen as an indirect pointing device / trackpad.

Reference behavior:

```text
Anland touchpad_mode = true
Plasma shell       = org.kde.plasma.desktop
```

Reference script:

```bash
#!/bin/bash

echo desktop > /data/local/tmp/anland-bridge/cmd

pkill -x plasmashell 2>/dev/null || true
sleep 1
nohup plasmashell --replace -p org.kde.plasma.desktop \
  >"$HOME/.local/share/plasma-desktop.log" 2>&1 &
disown
```

## Touch Mode

Purpose: direct touch interaction using Plasma Mobile.

Reference behavior:

```text
Anland touchpad_mode = false
Plasma shell       = org.kde.plasma.mobileshell
```

Reference script:

```bash
#!/bin/bash

echo touch > /data/local/tmp/anland-bridge/cmd

pkill -x plasmashell 2>/dev/null || true
sleep 1
nohup plasmashell --replace -p org.kde.plasma.mobileshell \
  >"$HOME/.local/share/plasma-mobile.log" 2>&1 &
disown
```

## User launchers

Validated launchers:

```text
~/.local/share/applications/plasma-desktop-mode.desktop
~/.local/share/applications/plasma-touch-mode.desktop
```

The old tablet/toggle launcher was removed from the final visible configuration.

## Future architecture

These scripts are retained as the known-working reference implementation. The long-term target is to replace the `/data/local/tmp` communication with the Android Bridge, while keeping the user-facing behavior unchanged.
