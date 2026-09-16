#!/bin/bash

set -e

BACKUP="$HOME/.config/plasma-desktop-before-tablet.js"

echo
echo "=============================================="
echo "        KDE TRUE TABLET / ANDROID MODE"
echo "=============================================="
echo

# ============================================================
# BACKUP DEL LAYOUT ATTUALE
# ============================================================

if [ ! -f "$BACKUP" ]; then
    qdbus6 org.kde.plasmashell \
        /PlasmaShell \
        org.kde.PlasmaShell.dumpCurrentLayoutJS \
        > "$BACKUP"

    echo "[OK] Layout Desktop salvato:"
    echo "     $BACKUP"
else
    echo "[OK] Backup già presente."
fi


# ============================================================
# CONFIGURAZIONE PLASMA
# ============================================================

qdbus6 org.kde.plasmashell \
    /PlasmaShell \
    org.kde.PlasmaShell.evaluateScript '

var p = panels()[0];

if (!p) {
    print("ERRORE: nessun pannello Plasma.");
} else {

    print("Configurazione pannello Tablet...");

    // --------------------------------------------------------
    // ANDROID NAVIGATION BAR
    // --------------------------------------------------------

    p.height = 72;

    p.minimumLength = p.maximumLength;
    p.length = p.maximumLength;

    p.alignment = "center";
    p.offset = 0;

    // pannello sempre visibile
    p.hiding = "none";


    // --------------------------------------------------------
    // WIDGET DEL PANNELLO
    // --------------------------------------------------------

    var widgets = p.widgets();


    // --------------------------------------------------------
    // RIMUOVI PAGINER
    // --------------------------------------------------------

    widgets.filter(function(w) {
        return w.type === "org.kde.plasma.pager";
    }).forEach(function(w) {
        print("Tablet: rimuovo Pager ID=" + w.id);
        w.remove();
    });


    // --------------------------------------------------------
    // RIMUOVI SHOW DESKTOP
    // --------------------------------------------------------

    widgets.filter(function(w) {
        return w.type === "org.kde.plasma.showdesktop";
    }).forEach(function(w) {
        print("Tablet: rimuovo ShowDesktop ID=" + w.id);
        w.remove();
    });


    // --------------------------------------------------------
    // RIMUOVI KICKOFF CLASSICO
    // --------------------------------------------------------

    widgets.filter(function(w) {
        return w.type === "org.kde.plasma.kickoff";
    }).forEach(function(w) {
        print("Tablet: rimuovo Kickoff classico ID=" + w.id);
        w.remove();
    });


    // --------------------------------------------------------
    // RIMUOVI EVENTUALI DRAWER DUPLICATI
    // --------------------------------------------------------

    widgets.filter(function(w) {
        return w.type === "p-connor.plasma-drawer";
    }).forEach(function(w, i) {
        if (i > 0) {
            print("Tablet: rimuovo Drawer duplicato ID=" + w.id);
            w.remove();
        }
    });


    // --------------------------------------------------------
    // CREA IL DRAWER ANDROID / HOME
    // --------------------------------------------------------

    var drawers = p.widgets().filter(function(w) {
        return w.type === "p-connor.plasma-drawer";
    });

    if (drawers.length === 0) {

        var drawer = p.addWidget(
            "p-connor.plasma-drawer"
        );

        print(
            "Tablet: HOME / APP LAUNCHER creato ID=" +
            drawer.id
        );

    } else {

        print(
            "Tablet: HOME / APP LAUNCHER già presente ID=" +
            drawers[0].id
        );
    }


    // --------------------------------------------------------
    // REPORT FINALE
    // --------------------------------------------------------

    print("");
    print("========== TABLET PANEL ==========");

    p.widgets().forEach(function(w) {

        print(
            "ID=" +
            w.id +
            " TYPE=" +
            w.type
        );

    });

    print("==================================");
}
'


# ============================================================
# KDE VIRTUAL KEYBOARD
# ============================================================

kwriteconfig6 \
    --notify \
    --file "$HOME/.config/kwinrc" \
    --group Wayland \
    --key InputMethod \
    "/usr/share/applications/org.kde.plasma.keyboard.desktop"


# ============================================================
# KWIN RELOAD
# ============================================================

qdbus6 org.kde.KWin \
    /KWin \
    org.kde.KWin.reconfigure \
    2>/dev/null || true


# ============================================================
# RISULTATO
# ============================================================

echo
echo "=============================================="
echo "       TRUE TABLET MODE ATTIVATA"
echo "=============================================="
echo
echo " HOME / APP LAUNCHER       : ATTIVO"
echo " TASKBAR                   : ATTIVA"
echo " PAGER                     : RIMOSSO"
echo " SHOW DESKTOP              : RIMOSSO"
echo " KICKOFF CLASSICO          : RIMOSSO"
echo " PANEL                     : 72 px"
echo " PANEL                     : FULL WIDTH"
echo " PANEL AUTOHIDE            : OFF"
echo " VIRTUAL KEYBOARD          : ATTIVA"
echo
echo "Backup Desktop:"
echo "$BACKUP"
echo
