#!/bin/bash
set -e

BIN="$HOME/.local/bin"
APPS="$HOME/.local/share/applications"
mkdir -p "$BIN" "$APPS"

cat > "$BIN/plasma-touch-mode" <<'SCRIPT'
#!/bin/bash
pkill -x plasmashell 2>/dev/null || true
sleep 1
nohup plasmashell --replace -p org.kde.plasma.mobileshell \
  >"$HOME/.local/share/plasma-mobile.log" 2>&1 &
disown
SCRIPT

cat > "$BIN/plasma-desktop-mode" <<'SCRIPT'
#!/bin/bash
pkill -x plasmashell 2>/dev/null || true
sleep 1
nohup plasmashell --replace -p org.kde.plasma.desktop \
  >"$HOME/.local/share/plasma-desktop.log" 2>&1 &
disown
SCRIPT

cat > "$BIN/plasma-toggle-mode" <<'SCRIPT'
#!/bin/bash
if pgrep -af 'plasmashell.*org.kde.plasma.mobileshell' >/dev/null; then
    "$HOME/.local/bin/plasma-desktop-mode"
else
    "$HOME/.local/bin/plasma-touch-mode"
fi
SCRIPT

chmod +x "$BIN/plasma-touch-mode"
chmod +x "$BIN/plasma-desktop-mode"
chmod +x "$BIN/plasma-toggle-mode"

cat > "$APPS/plasma-touch-mode.desktop" <<EOF2
[Desktop Entry]
Name=Plasma Touch
Comment=Passa a Plasma Mobile
Exec=$BIN/plasma-touch-mode
Icon=preferences-desktop-display
Terminal=false
Type=Application
Categories=Settings;
EOF2

cat > "$APPS/plasma-desktop-mode.desktop" <<EOF2
[Desktop Entry]
Name=Plasma Desktop
Comment=Passa a Plasma Desktop
Exec=$BIN/plasma-desktop-mode
Icon=preferences-desktop-display
Terminal=false
Type=Application
Categories=Settings;
EOF2

cat > "$APPS/plasma-toggle-mode.desktop" <<EOF2
[Desktop Entry]
Name=Plasma Toggle
Comment=Alterna tra Desktop e Touch
Exec=$BIN/plasma-toggle-mode
Icon=preferences-desktop-display
Terminal=false
Type=Application
Categories=Settings;
EOF2

chmod 644 "$APPS"/plasma-*-mode.desktop

update-desktop-database "$APPS" 2>/dev/null || true

echo
echo "======================================"
echo "  MODALITÀ PLASMA CONFIGURATE"
echo "======================================"
echo
echo "Comandi:"
echo "  plasma-desktop-mode"
echo "  plasma-touch-mode"
echo "  plasma-toggle-mode"
echo
echo "Icone create nel Launcher KDE."
