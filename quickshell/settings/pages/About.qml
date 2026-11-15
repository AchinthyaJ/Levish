import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../components"

// About page: only facts this shell can verify. No version or build numbers are invented.
Flickable {
    id: page
    property var themeStore
    property string pageId: ""
    property string keywords: "about levish version reset restore defaults runtime quickshell hyprland"
    readonly property var resetPaths: []
    readonly property color accent: themeStore.accentColor
    property bool confirmReset: false
    signal restoreDefaults()

    contentHeight: col.implicitHeight + 40
    clip: true

    ColumnLayout {
        id: col
        x: 24; y: 20
        width: page.width - 48
        spacing: 14

        SettingsCard {
            title: "Levish"
            Text { text: "Levish shell"; color: page.accent; font.pixelSize: 20; font.weight: Font.Bold }
            Text {
                text: "A Quickshell desktop shell for Hyprland. Runtime: Quickshell, Qt 6 and QML, Hyprland IPC, and a Python backend."
                color: "#c9d6e8"; font.pixelSize: 12; wrapMode: Text.Wrap; width: col.width - 32
            }
        }

        SettingsCard {
            title: "Configuration"
            SettingsRow { label: "Settings file"; hint: page.themeStore.configPath }
            SettingsRow { label: "Reset all Levish settings"
                hint: "Restores every value in this app to its default. Your pinned apps are kept."
                SettingsButton {
                    danger: true
                    text: page.confirmReset ? "Click again to confirm" : "Restore defaults"
                    onClicked: {
                        if (page.confirmReset) { page.confirmReset = false; page.restoreDefaults() }
                        else page.confirmReset = true
                    }
                }
            }
        }
    }
}
