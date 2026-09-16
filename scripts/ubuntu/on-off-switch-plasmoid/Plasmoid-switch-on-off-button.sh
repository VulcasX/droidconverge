#!/bin/bash

# KDE Plasma 6.5 On/Off Switch Commands Plasmoid Installer (Compact Mode)
# This script installs and configures the plasmoid for KDE Plasma 6

set -e

PLASMOID_NAME="org.kde.plasma.onoffswitch"
INSTALL_DIR="$HOME/.local/share/plasma/plasmoids/$PLASMOID_NAME"

echo "========================================="
echo "KDE Plasma 6.5 On/Off Switch Installer"
echo "========================================="
echo ""

# Check if running KDE Plasma
if [ -z "$KDE_SESSION_VERSION" ]; then
    echo "Warning: KDE Plasma session not detected. Continuing anyway..."
fi

# Create directory structure
echo "Creating directory structure..."
mkdir -p "$INSTALL_DIR/contents/ui"
mkdir -p "$INSTALL_DIR/contents/config"

# Create metadata.json (Plasma 6 uses JSON instead of desktop files)
echo "Creating metadata.json..."
cat > "$INSTALL_DIR/metadata.json" << 'EOF'
{
    "KPlugin": {
        "Authors": [
            {
                "Email": "intika@intika.com",
                "Name": "Intika"
            }
        ],
        "Category": "Utilities",
        "Description": "Widely configurable On/Off switch commands plasmoid",
        "Icon": "system-switch-user",
        "Id": "org.kde.plasma.onoffswitch",
        "License": "GPL-2.0+",
        "Name": "On/Off Switch Commands",
        "Version": "2.3.0",
        "Website": "https://github.com/Intika-KDE-Plasmoids/plasmoid-on-off-switch-commands"
    },
    "KPackageStructure": "Plasma/Applet",
    "X-Plasma-API-Minimum-Version": "6.0",
    "X-Plasma-Provides": [
        "org.kde.plasma.onoffswitch"
    ]
}
EOF

# Create main.qml with compact spacing and startup state options
echo "Creating main.qml..."
cat > "$INSTALL_DIR/contents/ui/main.qml" << 'EOF'
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    property bool switchState: true
    property bool isInactive: false
    property string currentStateText: ""
    property int executionType: 0 // 0=normal, 1=check, 2=watcher

    preferredRepresentation: fullRepresentation

    Component.onCompleted: {
        // Handle startup state based on configuration
        // startupState: 0=ON, 1=OFF, 2=Inactive
        var startupState = plasmoid.configuration.startupState

        if (startupState === 0) {
            // ON state
            switchState = true
            isInactive = false
            updateState()
            if (plasmoid.configuration.executeCommandOnStartup) {
                executeCommand(true)
            }
        } else if (startupState === 1) {
            // OFF state
            switchState = false
            isInactive = false
            updateState()
            if (plasmoid.configuration.executeCommandOnStartup) {
                executeCommand(false)
            }
        } else if (startupState === 2) {
            // Inactive state
            switchState = false
            isInactive = true
            updateState()
            // Don't execute any command for inactive state
        }

        // Legacy support for toggleOnStartup (deprecated but kept for compatibility)
        if (plasmoid.configuration.toggleOnStartup && startupState === 0) {
            executeCommand(true)
        } else if (plasmoid.configuration.watchStateOnStartup) {
            checkCurrentState()
        }

        if (plasmoid.configuration.watcherEnabled) {
            watcherTimer.start()
        }
    }

    Timer {
        id: watcherTimer
        interval: plasmoid.configuration.watcherInterval * 1000
        running: false
        repeat: true
        onTriggered: {
            if (plasmoid.configuration.watcherCommand.trim() !== "") {
                executeWatcherCommand()
            }
        }
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            var exitCode = data["exit code"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]

            disconnectSource(sourceName)

            if (executionType === 2) {
                handleWatcherResult(exitCode, stdout)
            } else if (executionType === 1) {
                handleCheckResult(exitCode)
            } else {
                handleCommandResult(exitCode, stdout, stderr)
            }

            executionType = 0
        }

        function exec(cmd, type) {
            if (cmd.trim() === "") return
            executionType = type
            connectSource(cmd)
        }
    }

    function executeCommand(newState) {
        var cmd = newState ? plasmoid.configuration.commandOn : plasmoid.configuration.commandOff

        if (cmd.trim() === "") {
            switchState = newState
            updateState()
            return
        }

        if (plasmoid.configuration.checkExecution) {
            executable.exec(cmd, 1) // check type
        } else {
            executable.exec(cmd, 0) // normal type
            switchState = newState
            updateState()
        }
    }

    function checkCurrentState() {
        var cmd = plasmoid.configuration.commandOn
        if (cmd.trim() !== "") {
            executable.exec(cmd, 1) // check type
        }
    }

    function executeWatcherCommand() {
        var cmd = plasmoid.configuration.watcherCommand
        if (cmd.trim() !== "") {
            executable.exec(cmd, 2) // watcher type
        }
    }

    function handleCommandResult(exitCode, stdout, stderr) {
        // Command executed, state remains as set
        updateState()
    }

    function handleCheckResult(exitCode) {
        switchState = (exitCode === 0)
        updateState()
    }

    function handleWatcherResult(exitCode, stdout) {
        if (exitCode === 0) {
            switchState = true
            isInactive = false
        } else {
            switchState = false
            if (plasmoid.configuration.customInactiveState) {
                isInactive = true
            }
        }
        updateState()
    }

    function updateState() {
        if (isInactive) {
            currentStateText = plasmoid.configuration.textInactive
        } else if (switchState) {
            currentStateText = plasmoid.configuration.textOn
        } else {
            currentStateText = plasmoid.configuration.textOff
        }

        toolTipMainText = plasmoid.configuration.tooltipText || "On/Off Switch"
    }

    function getBackgroundColor() {
        var color
        if (isInactive) {
            color = plasmoid.configuration.colorInactive
        } else if (switchState) {
            color = plasmoid.configuration.colorOn
        } else {
            color = plasmoid.configuration.colorOff
        }

        // Apply transparency
        var opacity = plasmoid.configuration.backgroundOpacity / 100.0
        return Qt.rgba(
            parseInt(color.substr(1,2), 16) / 255.0,
            parseInt(color.substr(3,2), 16) / 255.0,
            parseInt(color.substr(5,2), 16) / 255.0,
            opacity
        )
    }

    function getBorderColor() {
        if (isInactive) {
            return plasmoid.configuration.borderColorInactive
        } else if (switchState) {
            return plasmoid.configuration.borderColorOn
        } else {
            return plasmoid.configuration.borderColorOff
        }
    }

    function getTextColor() {
        if (isInactive) {
            return plasmoid.configuration.textColorInactive
        } else if (switchState) {
            return plasmoid.configuration.textColorOn
        } else {
            return plasmoid.configuration.textColorOff
        }
    }

    toolTipMainText: plasmoid.configuration.tooltipText || "On/Off Switch"
    toolTipSubText: currentStateText

    fullRepresentation: Item {
        // Compact mode: minimal spacing, tight fit
        Layout.minimumWidth: plasmoid.configuration.buttonWidth > 0 ? plasmoid.configuration.buttonWidth : switchButton.implicitWidth
        Layout.minimumHeight: plasmoid.configuration.buttonHeight > 0 ? plasmoid.configuration.buttonHeight : switchButton.implicitHeight
        Layout.preferredWidth: plasmoid.configuration.buttonWidth > 0 ? plasmoid.configuration.buttonWidth : switchButton.implicitWidth
        Layout.preferredHeight: plasmoid.configuration.buttonHeight > 0 ? plasmoid.configuration.buttonHeight : switchButton.implicitHeight
        // Remove extra margins
        Layout.leftMargin: 0
        Layout.rightMargin: 0
        Layout.topMargin: 0
        Layout.bottomMargin: 0

        PlasmaComponents.Button {
            id: switchButton
            anchors.fill: parent
            anchors.margins: 0  // No margins between buttons
            width: plasmoid.configuration.buttonWidth > 0 ? plasmoid.configuration.buttonWidth : implicitWidth
            height: plasmoid.configuration.buttonHeight > 0 ? plasmoid.configuration.buttonHeight : implicitHeight
            text: currentStateText
            checkable: true
            checked: switchState
            padding: plasmoid.configuration.buttonPadding

            background: Rectangle {
                color: getBackgroundColor()
                radius: 4
                border.color: getBorderColor()
                border.width: plasmoid.configuration.borderWidth
            }

            contentItem: Text {
                text: switchButton.text
                color: getTextColor()
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: plasmoid.configuration.fontSize > 0 ? plasmoid.configuration.fontSize : 12
                leftPadding: plasmoid.configuration.buttonPadding
                rightPadding: plasmoid.configuration.buttonPadding
                topPadding: plasmoid.configuration.buttonPadding
                bottomPadding: plasmoid.configuration.buttonPadding
            }

            onClicked: {
                isInactive = false
                executeCommand(!switchState)
            }
        }
    }
}
EOF

# Create config.qml
echo "Creating config.qml..."
cat > "$INSTALL_DIR/contents/ui/config.qml" << 'EOF'
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_commandOn: commandOnField.text
    property alias cfg_commandOff: commandOffField.text
    property alias cfg_textOn: textOnField.text
    property alias cfg_textOff: textOffField.text
    property alias cfg_textInactive: textInactiveField.text
    property alias cfg_tooltipText: tooltipField.text
    property alias cfg_startupState: startupStateCombo.currentIndex
    property alias cfg_executeCommandOnStartup: executeCommandCheck.checked
    property alias cfg_toggleOnStartup: toggleOnStartupCheck.checked
    property alias cfg_watchStateOnStartup: watchStateStartupCheck.checked
    property alias cfg_checkExecution: checkExecutionCheck.checked
    property alias cfg_customInactiveState: inactiveStateCheck.checked
    property alias cfg_colorOn: colorOnField.text
    property alias cfg_colorOff: colorOffField.text
    property alias cfg_colorInactive: colorInactiveField.text
    property alias cfg_textColorOn: textColorOnField.text
    property alias cfg_textColorOff: textColorOffField.text
    property alias cfg_textColorInactive: textColorInactiveField.text
    property alias cfg_watcherEnabled: watcherEnabledCheck.checked
    property alias cfg_watcherCommand: watcherCommandField.text
    property alias cfg_watcherInterval: watcherIntervalSpin.value
    property alias cfg_backgroundOpacity: opacitySpin.value
    property alias cfg_borderWidth: borderWidthSpin.value
    property alias cfg_borderColorOn: borderColorOnField.text
    property alias cfg_borderColorOff: borderColorOffField.text
    property alias cfg_borderColorInactive: borderColorInactiveField.text
    property alias cfg_buttonPadding: buttonPaddingSpin.value
    property alias cfg_buttonWidth: buttonWidthSpin.value
    property alias cfg_buttonHeight: buttonHeightSpin.value
    property alias cfg_fontSize: fontSizeSpin.value

    ColumnLayout {
        spacing: 10

        GroupBox {
            Layout.fillWidth: true
            title: "Commands"

            ColumnLayout {
                anchors.fill: parent

                Label { text: "Command On:" }
                TextField {
                    id: commandOnField
                    Layout.fillWidth: true
                    placeholderText: "Command to execute when turning on"
                }

                Label { text: "Command Off:" }
                TextField {
                    id: commandOffField
                    Layout.fillWidth: true
                    placeholderText: "Command to execute when turning off"
                }
            }
        }

        GroupBox {
            Layout.fillWidth: true
            title: "Display Text"

            ColumnLayout {
                anchors.fill: parent

                Label { text: "Text On:" }
                TextField {
                    id: textOnField
                    Layout.fillWidth: true
                    placeholderText: "ON"
                }

                Label { text: "Text Off:" }
                TextField {
                    id: textOffField
                    Layout.fillWidth: true
                    placeholderText: "OFF"
                }

                Label { text: "Text Inactive:" }
                TextField {
                    id: textInactiveField
                    Layout.fillWidth: true
                    placeholderText: "INACTIVE"
                }

                Label { text: "Tooltip:" }
                TextField {
                    id: tooltipField
                    Layout.fillWidth: true
                    placeholderText: "On/Off Switch"
                }
            }
        }

        GroupBox {
            Layout.fillWidth: true
            title: "Button Size & Appearance"

            GridLayout {
                anchors.fill: parent
                columns: 2

                Label { text: "Button Width (px, 0=auto):" }
                SpinBox {
                    id: buttonWidthSpin
                    from: 0
                    to: 500
                    value: 0
                    Layout.fillWidth: true
                }

                Label { text: "Button Height (px, 0=auto):" }
                SpinBox {
                    id: buttonHeightSpin
                    from: 0
                    to: 500
                    value: 0
                    Layout.fillWidth: true
                }

                Label { text: "Font Size (px, 0=default):" }
                SpinBox {
                    id: fontSizeSpin
                    from: 0
                    to: 72
                    value: 0
                    Layout.fillWidth: true
                }

                Label { text: "Background Opacity (%):" }
                SpinBox {
                    id: opacitySpin
                    from: 0
                    to: 100
                    value: 100
                    Layout.fillWidth: true
                }

                Label { text: "Border Width (px):" }
                SpinBox {
                    id: borderWidthSpin
                    from: 0
                    to: 10
                    value: 1
                    Layout.fillWidth: true
                }

                Label { text: "Button Padding (px):" }
                SpinBox {
                    id: buttonPaddingSpin
                    from: 0
                    to: 50
                    value: 8
                    Layout.fillWidth: true
                }
            }
        }

        GroupBox {
            Layout.fillWidth: true
            title: "Background Colors"

            GridLayout {
                anchors.fill: parent
                columns: 2

                Label { text: "Background On:" }
                TextField {
                    id: colorOnField
                    Layout.fillWidth: true
                    placeholderText: "#4CAF50"
                }

                Label { text: "Background Off:" }
                TextField {
                    id: colorOffField
                    Layout.fillWidth: true
                    placeholderText: "#F44336"
                }

                Label { text: "Background Inactive:" }
                TextField {
                    id: colorInactiveField
                    Layout.fillWidth: true
                    placeholderText: "#a1a9b1"
                }
            }
        }

        GroupBox {
            Layout.fillWidth: true
            title: "Border Colors"

            GridLayout {
                anchors.fill: parent
                columns: 2

                Label { text: "Border On:" }
                TextField {
                    id: borderColorOnField
                    Layout.fillWidth: true
                    placeholderText: "#45A049"
                }

                Label { text: "Border Off:" }
                TextField {
                    id: borderColorOffField
                    Layout.fillWidth: true
                    placeholderText: "#D32F2F"
                }

                Label { text: "Border Inactive:" }
                TextField {
                    id: borderColorInactiveField
                    Layout.fillWidth: true
                    placeholderText: "#a1a9b1"
                }
            }
        }

        GroupBox {
            Layout.fillWidth: true
            title: "Text Colors"

            GridLayout {
                anchors.fill: parent
                columns: 2

                Label { text: "Text Color On:" }
                TextField {
                    id: textColorOnField
                    Layout.fillWidth: true
                    placeholderText: "#FCFCFC"
                }

                Label { text: "Text Color Off:" }
                TextField {
                    id: textColorOffField
                    Layout.fillWidth: true
                    placeholderText: "#FCFCFC"
                }

                Label { text: "Text Color Inactive:" }
                TextField {
                    id: textColorInactiveField
                    Layout.fillWidth: true
                    placeholderText: "#FCFCFC"
                }
            }
        }

        GroupBox {
            Layout.fillWidth: true
            title: "Startup Behavior"

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                RowLayout {
                    Label {
                        text: "Initial State:"
                        Layout.minimumWidth: 100
                    }
                    ComboBox {
                        id: startupStateCombo
                        Layout.fillWidth: true
                        model: ["ON", "OFF", "Inactive"]
                        currentIndex: 0
                    }
                }

                CheckBox {
                    id: executeCommandCheck
                    text: "Execute command on startup (for ON/OFF states)"
                    ToolTip.visible: hovered
                    ToolTip.text: "When enabled, the corresponding command will be executed on startup based on the initial state (ON or OFF). Inactive state never executes commands."
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#cccccc"
                    Layout.topMargin: 5
                    Layout.bottomMargin: 5
                }

                Label {
                    text: "Legacy Options (deprecated):"
                    font.italic: true
                    font.pixelSize: 10
                }

                CheckBox {
                    id: toggleOnStartupCheck
                    text: "Execute ON command on startup (legacy)"
                    font.pixelSize: 10
                    enabled: false
                    opacity: 0.6
                }

                CheckBox {
                    id: watchStateStartupCheck
                    text: "Watch state on startup (legacy)"
                    font.pixelSize: 10
                    enabled: !toggleOnStartupCheck.checked
                    opacity: 0.6
                }
            }
        }

        GroupBox {
            Layout.fillWidth: true
            title: "Behavior"

            ColumnLayout {
                anchors.fill: parent

                CheckBox {
                    id: checkExecutionCheck
                    text: "Check execution state"
                }

                CheckBox {
                    id: inactiveStateCheck
                    text: "Enable custom inactive state"
                }
            }
        }

        GroupBox {
            Layout.fillWidth: true
            title: "Watcher"

            ColumnLayout {
                anchors.fill: parent

                CheckBox {
                    id: watcherEnabledCheck
                    text: "Enable watcher"
                }

                Label { text: "Watcher Command:" }
                TextField {
                    id: watcherCommandField
                    Layout.fillWidth: true
                    placeholderText: "Command to check state periodically"
                    enabled: watcherEnabledCheck.checked
                }

                RowLayout {
                    Label { text: "Interval (seconds):" }
                    SpinBox {
                        id: watcherIntervalSpin
                        from: 1
                        to: 3600
                        value: 5
                        enabled: watcherEnabledCheck.checked
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
EOF

# Create config XML files
echo "Creating configuration files..."
cat > "$INSTALL_DIR/contents/config/main.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<kcfg xmlns="http://www.kde.org/standards/kcfg/1.0"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://www.kde.org/standards/kcfg/1.0
      http://www.kde.org/standards/kcfg/1.0/kcfg.xsd" >
  <kcfgfile name=""/>

  <group name="General">
    <entry name="commandOn" type="String">
      <default></default>
    </entry>
    <entry name="commandOff" type="String">
      <default></default>
    </entry>
    <entry name="textOn" type="String">
      <default>ON</default>
    </entry>
    <entry name="textOff" type="String">
      <default>OFF</default>
    </entry>
    <entry name="textInactive" type="String">
      <default>INACTIVE</default>
    </entry>
    <entry name="tooltipText" type="String">
      <default>On/Off Switch</default>
    </entry>
    <entry name="startupState" type="Int">
      <default>0</default>
    </entry>
    <entry name="executeCommandOnStartup" type="Bool">
      <default>false</default>
    </entry>
    <entry name="toggleOnStartup" type="Bool">
      <default>true</default>
    </entry>
    <entry name="watchStateOnStartup" type="Bool">
      <default>false</default>
    </entry>
    <entry name="checkExecution" type="Bool">
      <default>false</default>
    </entry>
    <entry name="customInactiveState" type="Bool">
      <default>false</default>
    </entry>
    <entry name="colorOn" type="String">
      <default>#4CAF50</default>
    </entry>
    <entry name="colorOff" type="String">
      <default>#F44336</default>
    </entry>
    <entry name="colorInactive" type="String">
      <default>#9E9E9E</default>
    </entry>
    <entry name="textColorOn" type="String">
      <default>#FFFFFF</default>
    </entry>
    <entry name="textColorOff" type="String">
      <default>#FFFFFF</default>
    </entry>
    <entry name="textColorInactive" type="String">
      <default>#FFFFFF</default>
    </entry>
    <entry name="watcherEnabled" type="Bool">
      <default>false</default>
    </entry>
    <entry name="watcherCommand" type="String">
      <default></default>
    </entry>
    <entry name="watcherInterval" type="Int">
      <default>5</default>
    </entry>
    <entry name="backgroundOpacity" type="Int">
      <default>100</default>
    </entry>
    <entry name="borderWidth" type="Int">
      <default>1</default>
    </entry>
    <entry name="borderColorOn" type="String">
      <default>#45A049</default>
    </entry>
    <entry name="borderColorOff" type="String">
      <default>#D32F2F</default>
    </entry>
    <entry name="borderColorInactive" type="String">
      <default>#757575</default>
    </entry>
    <entry name="buttonPadding" type="Int">
      <default>8</default>
    </entry>
    <entry name="buttonWidth" type="Int">
      <default>0</default>
    </entry>
    <entry name="buttonHeight" type="Int">
      <default>0</default>
    </entry>
    <entry name="fontSize" type="Int">
      <default>0</default>
    </entry>
  </group>
</kcfg>
EOF

cat > "$INSTALL_DIR/contents/config/config.qml" << 'EOF'
import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: "General"
        icon: "preferences-system"
        source: "config.qml"
    }
}
EOF

echo ""
echo "Installation completed successfully!"
echo "Installation directory: $INSTALL_DIR"
echo ""
echo ""

echo "Installation Complete!"
echo "========================================="
echo ""
echo "NEW FEATURES:"
echo "- Startup state options: ON (default), OFF, or Inactive"
echo "- Optional command execution on startup"
echo "- Legacy startup options preserved for compatibility"
echo ""
echo "COMPACT MODE ENABLED:"
echo "- Removed external padding between buttons"
echo "- Minimal spacing (systray-like compact mode)"
echo "- Tight fit layout with zero margins"
echo ""
echo "To add the widget to your panel:"
echo "1. Right-click on your panel or desktop"
echo "2. Select 'Add Widgets...'"
echo "3. Search for 'On/Off Switch Commands'"
echo "4. Drag it to your panel or desktop"
echo ""
echo "To configure startup behavior:"
echo "1. Right-click on the widget"
echo "2. Select 'Configure On/Off Switch Commands...'"
echo "3. Go to 'Startup Behavior' section"
echo "4. Choose initial state: ON (default), OFF, or Inactive"
echo "5. Optionally enable 'Execute command on startup'"
echo ""
echo "Enjoy your enhanced KDE Plasma 6.5 plasmoid!"
echo ""
