import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../components"

// Top bar settings. Every control here is read by bar/Bar.qml or bar/Clock.qml.
Flickable {
    id: page
    property var themeStore
    property string pageId: ""
    ScrollBar.vertical: PageScrollBar { accent: page.themeStore.accentColor }
    property string keywords: "bar height clock 24 hour 12 seconds date gpu temperature workspace dots width radius"
    readonly property var resetPaths: ["bar.height", "bar.clock_format", "bar.show_date", "bar.show_seconds",
        "bar.show_gpu", "bar.show_temp", "bar.ws_width", "bar.ws_height", "bar.ws_radius",
        "bar.show_perf", "bar.show_workspaces", "bar.show_window_title", "bar.show_clock", "bar.show_status", "bar.show_tray",
        "bar.position", "bar.gap", "bar.side_margin", "bar.radius", "bar.border", "palette.bar"]
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
            title: "Placement"
            SettingsRow {
                label: "Edge"
                hint: "Which screen edge the bar sits on. Windows reserve its space."
                SettingsChoice { accent: page.accent
                    options: [{ value: "top", label: "Top" }, { value: "bottom", label: "Bottom" }]
                    current: page.themeStore.barPosition
                    onPicked: (v) => page.themeStore.set("bar.position", v) }
            }
            SettingsRow {
                label: "Distance from the edge"
                SettingsSlider { from: 0; to: 60; step: 1; suffix: " px"; accent: page.accent
                    value: page.themeStore.barGap
                    onCommitted: (v) => page.themeStore.set("bar.gap", v) }
            }
            SettingsRow {
                label: "Side margins"
                hint: "Leaves space on the left and right. Use with a distance from the edge to float the bar."
                SettingsSlider { from: 0; to: 200; step: 1; suffix: " px"; accent: page.accent
                    value: page.themeStore.barSideMargin
                    onCommitted: (v) => page.themeStore.set("bar.side_margin", v) }
            }
            SettingsRow {
                label: "Background colour"
                hint: "The solid colour behind the bar. Its transparency is set in Appearance → Glass."
                ColorField { themeStore: page.themeStore; path: "palette.bar"; accent: page.accent; width: 180 }
            }
            SettingsRow {
                label: "Corner radius"
                SettingsSlider { from: 0; to: 24; step: 1; suffix: " px"; accent: page.accent
                    value: page.themeStore.barRadius
                    onCommitted: (v) => page.themeStore.set("bar.radius", v) }
            }
            SettingsRow {
                label: "Outline"
                hint: "A thin light line around the bar. Off by default."
                SettingsSlider { from: 0; to: 100; step: 1; suffix: "%"; accent: page.accent
                    value: page.themeStore.barBorder * 100
                    onCommitted: (v) => page.themeStore.set("bar.border", v / 100) }
            }
        }

        SettingsCard {
            title: "Zones"
            // Hides a whole part of the bar. The rest of the bar moves to fill the space.
            SettingsRow {
                label: "Performance (CPU, GPU, temperature)"
                SettingsToggle { accent: page.accent; checked: page.themeStore.showPerf
                    onToggled: (v) => page.themeStore.set("bar.show_perf", v) }
            }
            SettingsRow {
                label: "Workspaces"
                SettingsToggle { accent: page.accent; checked: page.themeStore.showWorkspaces
                    onToggled: (v) => page.themeStore.set("bar.show_workspaces", v) }
            }
            SettingsRow {
                label: "Window title"
                SettingsToggle { accent: page.accent; checked: page.themeStore.showWindowTitle
                    onToggled: (v) => page.themeStore.set("bar.show_window_title", v) }
            }
            SettingsRow {
                label: "Clock"
                SettingsToggle { accent: page.accent; checked: page.themeStore.showClock
                    onToggled: (v) => page.themeStore.set("bar.show_clock", v) }
            }
            SettingsRow {
                label: "Status (network, Bluetooth, audio, battery)"
                SettingsToggle { accent: page.accent; checked: page.themeStore.showStatus
                    onToggled: (v) => page.themeStore.set("bar.show_status", v) }
            }
            SettingsRow {
                label: "System tray"
                SettingsToggle { accent: page.accent; checked: page.themeStore.showTray
                    onToggled: (v) => page.themeStore.set("bar.show_tray", v) }
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
