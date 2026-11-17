import QtQuick
import "../../common/Theme.js" as Theme
import "../../common/Version.js" as Version
import QtQuick.Layouts
import QtQuick.Controls
import "../components"
import "../../common" as Pal

// About page: the release version and runtime facts this shell can verify.
Flickable {
    id: page
    property var themeStore
    property string pageId: ""
    ScrollBar.vertical: PageScrollBar { accent: page.themeStore.accentColor }
    property string keywords: "about levish version reset restore defaults runtime quickshell hyprland"
    readonly property var resetPaths: []
    readonly property color accent: themeStore.accentColor
    property bool confirmReset: false
    property string importMessage: ""
    property bool importOk: true
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
            Text { text: "Levish " + Version.version; color: page.accent; font.pixelSize: Theme.fs(20); font.weight: Font.Bold }
            Text {
                text: "A Quickshell desktop shell for Hyprland. Runtime: Quickshell, Qt 6 and QML, Hyprland IPC, and a Python backend."
                color: Pal.Palette.textSecondary; font.pixelSize: Theme.fs(12); wrapMode: Text.Wrap; width: col.width - 32
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

        SettingsCard {
            title: "Export and import"
            SettingsRow {
                label: "Export settings"
                hint: "The settings as text. Select all and copy, or save it into a file."
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 120
                radius: 9
                color: Pal.Palette.controlFill
                border.color: Pal.Palette.controlEdge
                clip: true
                Flickable {
                    anchors { fill: parent; margins: 8 }
                    contentWidth: width
                    contentHeight: exportArea.implicitHeight
                    ScrollBar.vertical: PageScrollBar { accent: page.accent }
                    TextArea {
                        id: exportArea
                        width: parent.width
                        readOnly: true
                        wrapMode: TextArea.NoWrap
                        text: page.themeStore.exportText()
                        color: Pal.Palette.textSecondary
                        font.family: "monospace"
                        font.pixelSize: Theme.fs(11)
                        background: Item {}
                    }
                }
            }
            SettingsRow {
                label: "Import settings"
                hint: "Paste a settings file here. Only the keys it contains change. Invalid values are reset to defaults and listed."
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 120
                radius: 9
                color: Pal.Palette.controlFill
                border.color: importArea.activeFocus ? page.accent : Pal.Palette.controlEdge
                clip: true
                Flickable {
                    anchors { fill: parent; margins: 8 }
                    contentWidth: width
                    contentHeight: importArea.implicitHeight
                    ScrollBar.vertical: PageScrollBar { accent: page.accent }
                    TextArea {
                        id: importArea
                        width: parent.width
                        wrapMode: TextArea.NoWrap
                        placeholderText: "{ \"bar\": { \"height\": 36 } }"
                        placeholderTextColor: Pal.Palette.muted
                        color: Pal.Palette.text
                        font.family: "monospace"
                        font.pixelSize: Theme.fs(11)
                        background: Item {}
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                SettingsButton {
                    text: "Import"
                    enabled: importArea.text.trim() !== ""
                    onClicked: {
                        const r = page.themeStore.importText(importArea.text)
                        page.importMessage = r.ok
                            ? ("Imported " + r.applied + " setting(s)."
                               + (r.rejected.length ? " Reset to default: " + r.rejected.join(", ") + "." : ""))
                            : r.error
                        page.importOk = r.ok
                        if (r.ok) importArea.text = ""
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: page.importMessage
                    color: page.importOk ? Pal.Palette.ok : Pal.Palette.danger
                    font.pixelSize: Theme.fs(12)
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
