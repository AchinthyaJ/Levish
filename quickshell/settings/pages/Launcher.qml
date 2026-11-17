import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../common/Theme.js" as Theme
import "../components"
import "../../common" as Pal

// Application launcher settings. Read by launcher/Launcher.qml.
Flickable {
    id: page
    property var themeStore
    property string pageId: ""
    ScrollBar.vertical: PageScrollBar { accent: page.themeStore.accentColor }
    property string keywords: "launcher application menu grid list view columns default"
    readonly property var resetPaths: ["launcher.default_view", "launcher.columns", "launcher.icon_size", "launcher.sort", "launcher.hidden"]
    readonly property color accent: themeStore.accentColor

    contentHeight: col.implicitHeight + 40
    clip: true

    ColumnLayout {
        id: col
        x: 24; y: 20
        width: page.width - 48
        spacing: 14

        SettingsCard {
            title: "Opening view"
            SettingsRow {
                label: "Default view"
                hint: "The layout the launcher opens in. Switching views inside it does not change this."
                SettingsChoice { accent: page.accent
                    options: [{ value: "grid", label: "Grid" }, { value: "list", label: "List" }]
                    current: page.themeStore.launcherDefaultView
                    onPicked: (v) => page.themeStore.set("launcher.default_view", v) }
            }
            SettingsRow {
                label: "Grid columns"
                SettingsSlider { from: 3; to: 8; step: 1; accent: page.accent
                    value: page.themeStore.launcherColumns
                    onCommitted: (v) => page.themeStore.set("launcher.columns", v) }
            }
        }

        SettingsCard {
            title: "Applications"
            SettingsRow {
                label: "Icon size"
                SettingsSlider { from: 24; to: 72; step: 1; suffix: " px"; accent: page.accent
                    value: page.themeStore.launcherIconSize
                    onCommitted: (v) => page.themeStore.set("launcher.icon_size", v) }
            }
            SettingsRow {
                label: "Sort order"
                hint: "Pinned first keeps your pinned apps at the top, each group sorted by name."
                SettingsChoice { accent: page.accent
                    options: [{ value: "name", label: "Name" }, { value: "pinned_first", label: "Pinned first" }]
                    current: page.themeStore.launcherSort
                    onPicked: (v) => page.themeStore.set("launcher.sort", v) }
            }
            SettingsRow {
                label: "Hidden applications"
                hint: "Desktop IDs separated by commas, for example htop, avahi-discover. They stay installed and only leave the launcher."
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 64
                radius: 9
                color: Pal.Palette.controlFill
                border.color: hiddenField.activeFocus ? page.accent : Pal.Palette.controlEdge
                TextField {
                    id: hiddenField
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    text: page.themeStore.launcherHidden
                    placeholderText: "htop, avahi-discover"
                    placeholderTextColor: Pal.Palette.muted
                    color: Pal.Palette.text
                    font.pixelSize: Theme.fs(12)
                    background: Item {}
                    onEditingFinished: page.themeStore.set("launcher.hidden", text)
                }
            }
        }
    }
}
