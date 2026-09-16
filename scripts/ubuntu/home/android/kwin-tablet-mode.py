#!/usr/bin/python3

import sys
import subprocess
import os

import gi

gi.require_version("Gio", "2.0")
gi.require_version("GLib", "2.0")

from gi.repository import Gio, GLib


def usage():
    print("Uso: kwin-tablet-mode.py on|off")
    sys.exit(2)


if len(sys.argv) != 2 or sys.argv[1] not in ("on", "off"):
    usage()

mode = sys.argv[1]

# Scrive la configurazione che KWin leggerà.
subprocess.check_call([
    "kwriteconfig6",
    "--file", "kwinrc",
    "--group", "Input",
    "--key", "TabletMode",
    mode
])

# Lo script deve essere eseguito DENTRO la sessione Plasma.
bus_address = os.environ.get("DBUS_SESSION_BUS_ADDRESS")

if not bus_address:
    print("ERRORE: DBUS_SESSION_BUS_ADDRESS non presente.")
    print("Questo script deve essere lanciato dalla sessione grafica Plasma.")
    sys.exit(1)

connection = Gio.bus_get_sync(
    Gio.BusType.SESSION,
    None
)

Gio.DBusConnection.emit_signal(
    connection,
    None,
    "/kwinrc",
    "org.kde.kconfig.notify",
    "ConfigChanged",
    GLib.Variant.new_tuple(
        GLib.Variant(
            "a{saay}",
            {"Input": [b"TabletMode"]}
        )
    )
)

print("KWin TabletMode =", mode)
