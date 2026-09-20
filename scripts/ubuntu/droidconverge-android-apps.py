#!/usr/bin/env python3
"""List/launch Android apps through the authenticated local Bridge and build KDE entries."""
import json, os, re, socket, sys
from pathlib import Path

CONFIGS = (Path.home() / ".config/droidconverge.json",
           Path.home() / ".config/droidconverge/droidconverge.json")
TARGET = Path.home() / ".local/share/applications/droidconverge-android"

def request(action, state=None):
    config = next((path for path in CONFIGS if path.is_file()), None)
    if config is None: raise RuntimeError("Bridge config missing under ~/.config")
    cfg = json.loads(config.read_text(encoding="utf-8"))
    payload = {"id":"linux-cli", "action":action, "token":cfg["haptic_token"]}
    if state is not None: payload["state"] = state
    with socket.create_connection((cfg.get("host", "127.0.0.1"), int(cfg.get("port", 8765))), 3) as sock:
        sock.sendall((json.dumps(payload, separators=(",", ":")) + "\n").encode())
        line = sock.makefile("r", encoding="utf-8").readline()
    result = json.loads(line)
    if not result.get("ok"): raise RuntimeError(result.get("error") or result.get("data", {}).get("error", "bridge error"))
    return result.get("data", {})

def sync():
    TARGET.mkdir(parents=True, exist_ok=True)
    for old in TARGET.glob("*.desktop"): old.unlink()
    apps = request("android-apps").get("apps", [])
    script = Path(__file__).resolve()
    for app in apps:
        package = app.get("package", "")
        if not re.fullmatch(r"[A-Za-z0-9_.]{3,180}", package): continue
        label = str(app.get("label", package)).replace("\n", " ").replace("\r", " ")[:120]
        entry = "[Desktop Entry]\nType=Application\nName={} (Android)\nExec={} launch {}\nIcon=android\nCategories=Android;Utility;\nTerminal=false\n".format(label, script, package)
        (TARGET / (package + ".desktop")).write_text(entry, encoding="utf-8")
    print(f"Created {len(list(TARGET.glob('*.desktop')))} Android launchers in {TARGET}")

if __name__ == "__main__":
    if len(sys.argv) == 2 and sys.argv[1] == "sync": sync()
    elif len(sys.argv) == 3 and sys.argv[1] in ("wifi", "bluetooth") and sys.argv[2] in ("status", "on", "off"):
        print(json.dumps(request(sys.argv[1], sys.argv[2]), ensure_ascii=False))
    elif len(sys.argv) == 2 and sys.argv[1] in ("wifi-settings", "bluetooth-settings"):
        request(sys.argv[1])
    elif len(sys.argv) == 3 and sys.argv[1] == "launch": request("android-launch", sys.argv[2])
    else: raise SystemExit("Usage: droidconverge-android-apps {sync|launch PACKAGE|wifi status|on|off|bluetooth status|on|off|wifi-settings|bluetooth-settings}")
