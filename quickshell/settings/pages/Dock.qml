import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../components"

// Dock settings. Every control here is read by dock/Dock.qml through DockSettings.
Flickable {
    id: page
    property var themeStore
    property string pageId: ""
    property string keywords: "dock enable show hide auto icon size margin monitor screen display"
    readonly property var resetPaths: ["dock.enabled", "dock.auto_hide", "dock.icon_size", "dock.margin", "dock.monitor"]
    readonly property color accent: themeStore.accentColor

    // Monitor choices: first screen, all screens, then each connected screen by name.
    readonly property var monitorOptions: {
        const opts = [{ value: "", label: "First screen" }, { value: "all", label: "All screens" }]
        for (let i = 0; i < Quickshell.screens.length; i++) {
            const n = Quickshell.screens[i].name
            opts.push({ value: n, label: n })
        }
        return opts
    }

    contentHeight: col.implicitHeight + 40
    clip: true

    ColumnLayout {
        id: col
        x: 24; y: 20
        width: page.width - 48
        spacing: 14

        SettingsCard {
            title: "Visibility"
            SettingsRow {
                label: "Show dock"
                hint: "Turning the dock off hides it. Its pinned apps and settings are kept."
                SettingsToggle { accent: page.accent; checked: page.themeStore.dockEnabled
                    onToggled: (v) => page.themeStore.set("dock.enabled", v) }
            }
            SettingsRow {
                label: "Auto-hide"
                hint: "Slides the dock away until the pointer reaches its edge."
                SettingsToggle { accent: page.accent; checked: page.themeStore.dockAutoHide
                    onToggled: (v) => page.themeStore.set("dock.auto_hide", v) }
            }
        }

        SettingsCard {
            title: "Size and position"
            SettingsRow {
                label: "Icon size"
                SettingsSlider { from: 24; to: 96; step: 1; suffix: " px"; accent: page.accent
                    value: page.themeStore.dockIconSize
                    onCommitted: (v) => page.themeStore.set("dock.icon_size", v) }
            }
            SettingsRow {
                label: "Distance from the screen edge"
                SettingsSlider { from: 0; to: 200; step: 1; suffix: " px"; accent: page.accent
                    value: page.themeStore.dockMargin
                    onCommitted: (v) => page.themeStore.set("dock.margin", v) }
            }
            SettingsRow {
                label: "Monitor"
                hint: "Which screen shows the dock."
                SettingsChoice { accent: page.accent; options: page.monitorOptions
                    current: page.themeStore.dockMonitor
                    onPicked: (v) => page.themeStore.set("dock.monitor", v) }
            }
        }
    }
}
