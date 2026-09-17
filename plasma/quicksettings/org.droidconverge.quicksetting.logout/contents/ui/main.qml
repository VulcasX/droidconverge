// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import org.kde.plasma.private.mobileshell.quicksettingsplugin as QS

QS.QuickSetting {
    text: i18n("Log Out")
    status: i18n("Open logout menu")
    icon: "system-log-out-symbolic"

    enabled: false
    available: true

    // Replaced with the user's absolute path by install-plasma-logout.sh.
    settingsCommand: "@DROIDCONVERGE_LOGOUT_COMMAND@"
}
