import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../components"

// Top bar settings. Every control here is read by bar/Bar.qml or bar/Clock.qml.
Flickable {
    id: page
    property var themeStore
    property string pageId: ""
    property string keywords: "bar height clock 24 hour 12 seconds date gpu temperature workspace dots width radius"
    readonly property var resetPaths: ["bar.height", "bar.clock_format", "bar.show_date", "bar.show_seconds",
        "bar.show_gpu", "bar.show_temp", "bar.ws_width", "bar.ws_height", "bar.ws_radius"]
    readonly property color accent: themeStore.accentColor

    contentHeight: col.implicitHeight + 40
    clip: true

    ColumnLayout {
        id: col
        x: 24; y: 20
        width: page.width - 48
        spacing: 14

        SettingsCard {
            title: "Bar"
            SettingsRow {
                label: "Height"
                hint: "Pixels. Applies to the top bar immediately."
                SettingsSlider { from: 28; to: 60; step: 1; suffix: " px"; accent: page.accent
                    value: page.themeStore.barHeight
                    onCommitted: (v) => page.themeStore.set("bar.height", v) }
            }
        }

        SettingsCard {
            title: "Clock"
            SettingsRow {
                label: "Time format"
                SettingsChoice { accent: page.accent
                    options: [{ value: "HH:mm", label: "24-hour" }, { value: "hh:mm AP", label: "12-hour" }]
                    current: page.themeStore.clockFormat
                    onPicked: (v) => page.themeStore.set("bar.clock_format", v) }
            }
            SettingsRow {
                label: "Show seconds"
                SettingsToggle { accent: page.accent; checked: page.themeStore.showSeconds
                    onToggled: (v) => page.themeStore.set("bar.show_seconds", v) }
            }
            SettingsRow {
                label: "Show date"
                SettingsToggle { accent: page.accent; checked: page.themeStore.showDate
                    onToggled: (v) => page.themeStore.set("bar.show_date", v) }
            }
        }

        SettingsCard {
            title: "Indicators"
            SettingsRow {
                label: "GPU usage"
                SettingsToggle { accent: page.accent; checked: page.themeStore.showGpu
                    onToggled: (v) => page.themeStore.set("bar.show_gpu", v) }
            }
            SettingsRow {
                label: "CPU temperature"
                SettingsToggle { accent: page.accent; checked: page.themeStore.showTemp
                    onToggled: (v) => page.themeStore.set("bar.show_temp", v) }
            }
        }

        SettingsCard {
            title: "Workspaces"
            SettingsRow {
                label: "Active pill width"
                SettingsSlider { from: 20; to: 64; step: 1; suffix: " px"; accent: page.accent
                    value: page.themeStore.workspaceFocusedWidth
                    onCommitted: (v) => page.themeStore.set("bar.ws_width", v) }
            }
            SettingsRow {
                label: "Pill height"
                SettingsSlider { from: 8; to: 24; step: 1; suffix: " px"; accent: page.accent
                    value: page.themeStore.workspaceHeight
                    onCommitted: (v) => page.themeStore.set("bar.ws_height", v) }
            }
            SettingsRow {
                label: "Pill corner radius"
                SettingsSlider { from: 3; to: 12; step: 1; suffix: " px"; accent: page.accent
                    value: page.themeStore.workspaceRadius
                    onCommitted: (v) => page.themeStore.set("bar.ws_radius", v) }
            }
        }
    }
}
