import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../components"

// Application launcher settings. Read by launcher/Launcher.qml.
Flickable {
    id: page
    property var themeStore
    property string pageId: ""
    property string keywords: "launcher application menu grid list view columns default"
    readonly property var resetPaths: ["launcher.default_view", "launcher.columns"]
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
    }
}
