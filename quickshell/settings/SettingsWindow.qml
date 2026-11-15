// Levish Settings Application — Centralized configuration panel with live preview & reactivity.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../common" as C
import "../common/Theme.js" as Theme

PanelWindow {
    id: win
    required property var themeStore
    property bool open: false
    signal closeRequested()

    visible: open
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "#40000000"
    WlrLayershell.namespace: "levish-settings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property string currentTab: "appearance"

    readonly property var tabs: [
        { id: "appearance",  label: "Appearance",        icon: "sun"     },
        { id: "bar",         label: "Top Bar",           icon: "up"      },
        { id: "dock",        label: "Dock",              icon: "down"    },
        { id: "launcher",    label: "App Launcher",      icon: "apps"    },
        { id: "shortcuts",   label: "Shortcuts",         icon: "bolt"    },
        { id: "performance", label: "Performance",       icon: "cpu"     },
        { id: "displays",    label: "Displays",          icon: "grid"    },
        { id: "about",       label: "About Levish",      icon: "note"    }
    ]

    readonly property var accentColors: [
        { name: "Levish Aqua",    hex: "#c8f7ef" },
        { name: "Emerald Mint",  hex: "#34d399" },
        { name: "Sky Cyan",      hex: "#38bdf8" },
        { name: "Neon Violet",   hex: "#a855f7" },
        { name: "Cyberpunk Pink",hex: "#ff007f" },
        { name: "Rose Coral",    hex: "#f43f5e" },
        { name: "Golden Amber",  hex: "#f59e0b" },
        { name: "Pure White",    hex: "#ffffff" }
    ]

    MouseArea {
        anchors.fill: parent
        onClicked: win.closeRequested()
    }

    Item {
        anchors.fill: parent
        focus: win.open
        Keys.onEscapePressed: win.closeRequested()
    }

    Rectangle {
        id: dialog
        width: Math.min(960, Math.round(win.width * 0.78))
        height: Math.min(680, Math.round(win.height * 0.82))
        anchors.centerIn: parent
        radius: win.themeStore ? win.themeStore.cornerRadius : 16
        color: win.themeStore ? win.themeStore.glassColor : Theme.glass
        border.color: win.themeStore ? win.themeStore.glassEdge : Theme.glassEdge
        border.width: 1

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ── Left Sidebar Navigation ──────────────────────────────
            Rectangle {
                Layout.preferredWidth: 230
                Layout.fillHeight: true
                color: "#18000000"

                Rectangle {
                    anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                    width: 1
                    color: "#18ffffff"
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 4

                    // App Title with Prevalent Big Gear Icon
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 14
                        spacing: 10

                        Rectangle {
                            width: 38; height: 38
                            radius: 12
                            color: Qt.rgba(0.2, 0.4, 0.5, 0.4)
                            border.color: win.themeStore ? win.themeStore.accentColor : Theme.accent
                            border.width: 1.5

                            C.Icon {
                                anchors.centerIn: parent
                                width: 22; height: 22
                                kind: "gear"
                                tint: win.themeStore ? win.themeStore.accentColor : Theme.accent
                            }
                        }

                        ColumnLayout {
                            spacing: 1
                            Text {
                                text: "Levish Settings"
                                color: Theme.text
                                font.pixelSize: 15
                                font.weight: Font.Bold
                            }
                            Text {
                                text: "Shell Configuration"
                                color: Theme.muted
                                font.pixelSize: 10
                            }
                        }
                    }

                    // Section Items
                    Repeater {
                        model: win.tabs
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 38
                            radius: 8
                            readonly property bool isSelected: win.currentTab === modelData.id
                            color: isSelected
                                   ? (win.themeStore ? Qt.rgba(0.2, 0.35, 0.45, 0.4) : "#22ffffff")
                                   : (tabMA.containsMouse ? "#14ffffff" : "transparent")
                            border.color: isSelected ? (win.themeStore ? win.themeStore.accentColor : Theme.accent) : "transparent"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 120 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                C.Icon {
                                    width: 17; height: 17
                                    kind: modelData.icon
                                    tint: isSelected ? (win.themeStore ? win.themeStore.accentColor : Theme.accent) : Theme.muted
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.label
                                    color: isSelected ? Theme.text : Theme.muted
                                    font.pixelSize: 13
                                    font.weight: isSelected ? Font.DemiBold : Font.Normal
                                }
                            }

                            MouseArea {
                                id: tabMA
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.currentTab = modelData.id
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Reset to Defaults Button
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        radius: 8
                        color: resetMA.containsMouse ? "#33e94560" : "#14ffffff"
                        border.color: resetMA.containsMouse ? "#66e94560" : "#18ffffff"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Reset All to Defaults"
                            color: resetMA.containsMouse ? "#f0708a" : Theme.muted
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: resetMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.themeStore.resetToDefaults()
                        }
                    }
                }
            }

            // ── Right Main Settings Content ──────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 14

                    // Header row: Section title + Close button
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: {
                                for (let i = 0; i < win.tabs.length; i++)
                                    if (win.tabs[i].id === win.currentTab) return win.tabs[i].label
                                return "Settings"
                            }
                            color: Theme.text
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            implicitWidth: 30; implicitHeight: 30
                            radius: 15
                            color: closeMA.containsMouse ? "#33ffffff" : "#14ffffff"
                            border.color: "#22ffffff"
                            border.width: 1
                            C.Icon { anchors.centerIn: parent; width: 12; height: 12; kind: "close"; tint: Theme.text }
                            MouseArea {
                                id: closeMA
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.closeRequested()
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: "#18ffffff"
                    }

                    // Content Scroll Area
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        ColumnLayout {
                            width: parent.width - 16
                            spacing: 20

                            // ===================================================
                            // TAB 1: APPEARANCE (VAST CUSTOMIZATION)
                            // ===================================================
                            ColumnLayout {
                                visible: win.currentTab === "appearance"
                                Layout.fillWidth: true
                                spacing: 18

                                // Theme Presets
                                Text { text: "Preset Themes (One-Click Transformation)"; color: Theme.text; font.pixelSize: 14; font.weight: Font.Bold }
                                GridView {
                                    Layout.fillWidth: true
                                    implicitHeight: 130
                                    cellWidth: 160
                                    cellHeight: 60
                                    model: win.themeStore.presets
                                    interactive: false

                                    delegate: Rectangle {
                                        required property var modelData
                                        width: 150; height: 52
                                        radius: 10
                                        readonly property bool isCur: win.themeStore.currentPreset === modelData.name
                                        color: isCur ? Qt.rgba(0.2, 0.4, 0.5, 0.4) : "#14ffffff"
                                        border.color: isCur ? modelData.accent : "#22ffffff"
                                        border.width: isCur ? 2 : 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            spacing: 8

                                            Rectangle {
                                                width: 18; height: 18; radius: 9
                                                color: modelData.accent
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.name
                                                color: Theme.text
                                                font.pixelSize: 11
                                                font.weight: isCur ? Font.Bold : Font.Normal
                                                elide: Text.ElideRight
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: win.themeStore.applyPreset(modelData)
                                        }
                                    }
                                }

                                // Accent Color Swatches
                                Text { text: "Accent Color"; color: Theme.text; font.pixelSize: 14; font.weight: Font.Bold }
                                RowLayout {
                                    spacing: 12
                                    Repeater {
                                        model: win.accentColors
                                        delegate: Rectangle {
                                            required property var modelData
                                            width: 36; height: 36; radius: 18
                                            color: modelData.hex
                                            border.color: win.themeStore.accentColor === modelData.hex ? "#ffffff" : "transparent"
                                            border.width: 3
                                            scale: win.themeStore.accentColor === modelData.hex ? 1.15 : (clrMA.containsMouse ? 1.08 : 1)
                                            Behavior on scale { NumberAnimation { duration: 140 } }
                                            MouseArea {
                                                id: clrMA
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: win.themeStore.saveSetting("theme", "accent", modelData.hex)
                                            }
                                        }
                                    }
                                }

                                // Glass Opacity Slider
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "Glass Opacity (" + Math.round(win.themeStore.glassOpacity * 100) + "%)"
                                        color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold
                                        Layout.preferredWidth: 200
                                    }
                                    Slider {
                                        Layout.fillWidth: true
                                        from: 0.35; to: 1.0; stepSize: 0.05
                                        value: win.themeStore.glassOpacity
                                        onMoved: win.themeStore.saveSetting("theme", "opacity", value)
                                    }
                                }

                                // Corner Radius Slider
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "Corner Radius (" + win.themeStore.cornerRadius + " px)"
                                        color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold
                                        Layout.preferredWidth: 200
                                    }
                                    Slider {
                                        Layout.fillWidth: true
                                        from: 4; to: 28; stepSize: 2
                                        value: win.themeStore.cornerRadius
                                        onMoved: win.themeStore.saveSetting("theme", "radius", Math.round(value))
                                    }
                                }
                            }

                            // ===================================================
                            // TAB 2: TOP BAR (VAST CUSTOMIZATION)
                            // ===================================================
                            ColumnLayout {
                                visible: win.currentTab === "bar"
                                Layout.fillWidth: true
                                spacing: 18

                                Text { text: "Top Bar Dimensions & Layout"; color: Theme.text; font.pixelSize: 14; font.weight: Font.Bold }

                                // Bar Height
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "Bar Height (" + win.themeStore.barHeight + " px)"
                                        color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold
                                        Layout.preferredWidth: 220
                                    }
                                    Slider {
                                        Layout.fillWidth: true
                                        from: 30; to: 54; stepSize: 2
                                        value: win.themeStore.barHeight
                                        onMoved: win.themeStore.saveSetting("bar", "height", Math.round(value))
                                    }
                                }

                                // Workspace Focused Width
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "Active Workspace Width (" + win.themeStore.workspaceFocusedWidth + " px)"
                                        color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold
                                        Layout.preferredWidth: 220
                                    }
                                    Slider {
                                        Layout.fillWidth: true
                                        from: 24; to: 64; stepSize: 2
                                        value: win.themeStore.workspaceFocusedWidth
                                        onMoved: win.themeStore.saveSetting("bar", "ws_width", Math.round(value))
                                    }
                                }

                                // Workspace Pill Height (BIGGG dots)
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "Workspace Dots Height (" + win.themeStore.workspaceHeight + " px)"
                                        color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold
                                        Layout.preferredWidth: 220
                                    }
                                    Slider {
                                        Layout.fillWidth: true
                                        from: 8; to: 22; stepSize: 1
                                        value: win.themeStore.workspaceHeight
                                        onMoved: win.themeStore.saveSetting("bar", "ws_height", Math.round(value))
                                    }
                                }

                                Text { text: "Clock & Display Options"; color: Theme.text; font.pixelSize: 14; font.weight: Font.Bold; Layout.topMargin: 8 }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "24-Hour Time Format"; color: Theme.text; font.pixelSize: 13; Layout.fillWidth: true }
                                    Switch {
                                        checked: win.themeStore.clockFormat === "HH:mm"
                                        onToggled: win.themeStore.saveSetting("bar", "clock_format", checked ? "HH:mm" : "hh:mm A")
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Show Seconds"; color: Theme.text; font.pixelSize: 13; Layout.fillWidth: true }
                                    Switch {
                                        checked: win.themeStore.showSeconds
                                        onToggled: win.themeStore.saveSetting("bar", "show_seconds", checked)
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Show Date in Top Bar"; color: Theme.text; font.pixelSize: 13; Layout.fillWidth: true }
                                    Switch {
                                        checked: win.themeStore.showDate
                                        onToggled: win.themeStore.saveSetting("bar", "show_date", checked)
                                    }
                                }
                            }

                            // ===================================================
                            // TAB 3: DOCK (VAST CUSTOMIZATION)
                            // ===================================================
                            ColumnLayout {
                                visible: win.currentTab === "dock"
                                Layout.fillWidth: true
                                spacing: 18

                                Text { text: "Dock Behavior & Sizing"; color: Theme.text; font.pixelSize: 14; font.weight: Font.Bold }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Enable Application Dock"; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.fillWidth: true }
                                    Switch {
                                        checked: win.themeStore.dockEnabled
                                        onToggled: win.themeStore.saveSetting("dock", "enabled", checked)
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Dock Auto-Hide (Disabled by default)"; color: Theme.text; font.pixelSize: 13; Layout.fillWidth: true }
                                    Switch {
                                        checked: win.themeStore.dockAutoHide
                                        onToggled: win.themeStore.saveSetting("dock", "auto_hide", checked)
                                    }
                                }

                                // Dock Icon Size
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "Dock Icon Size (" + win.themeStore.dockIconSize + " px)"
                                        color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold
                                        Layout.preferredWidth: 220
                                    }
                                    Slider {
                                        Layout.fillWidth: true
                                        from: 32; to: 72; stepSize: 4
                                        value: win.themeStore.dockIconSize
                                        onMoved: win.themeStore.saveSetting("dock", "icon_size", Math.round(value))
                                    }
                                }

                                // Dock Bottom Margin
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "Dock Screen Margin (" + win.themeStore.dockMargin + " px)"
                                        color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold
                                        Layout.preferredWidth: 220
                                    }
                                    Slider {
                                        Layout.fillWidth: true
                                        from: 0; to: 36; stepSize: 2
                                        value: win.themeStore.dockMargin
                                        onMoved: win.themeStore.saveSetting("dock", "margin", Math.round(value))
                                    }
                                }
                            }

                            // ===================================================
                            // TAB 4: APP LAUNCHER
                            // ===================================================
                            ColumnLayout {
                                visible: win.currentTab === "launcher"
                                Layout.fillWidth: true
                                spacing: 18

                                Text { text: "Launcher View & Columns"; color: Theme.text; font.pixelSize: 14; font.weight: Font.Bold }

                                RowLayout {
                                    spacing: 14
                                    Button {
                                        text: "Default: Grid View"
                                        highlighted: win.themeStore.launcherDefaultView === "grid"
                                        onClicked: win.themeStore.saveSetting("launcher", "default_view", "grid")
                                    }
                                    Button {
                                        text: "Default: List View"
                                        highlighted: win.themeStore.launcherDefaultView === "list"
                                        onClicked: win.themeStore.saveSetting("launcher", "default_view", "list")
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "Grid Columns (" + win.themeStore.launcherColumns + ")"
                                        color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold
                                        Layout.preferredWidth: 200
                                    }
                                    Slider {
                                        Layout.fillWidth: true
                                        from: 4; to: 7; stepSize: 1
                                        value: win.themeStore.launcherColumns
                                        onMoved: win.themeStore.saveSetting("launcher", "columns", Math.round(value))
                                    }
                                }
                            }

                            // ===================================================
                            // TAB 5: KEYBOARD SHORTCUTS
                            // ===================================================
                            ColumnLayout {
                                visible: win.currentTab === "shortcuts"
                                Layout.fillWidth: true
                                spacing: 14

                                Text { text: "Configured Keyboard Shortcuts"; color: Theme.text; font.pixelSize: 14; font.weight: Font.Bold }

                                Repeater {
                                    model: [
                                        { key: "SUPER, SPACE", desc: "Open Application Launcher" },
                                        { key: "SUPER, C",     desc: "Toggle Control Center" },
                                        { key: "SUPER, P",     desc: "Toggle Performance Panel" },
                                        { key: "SUPER, B",     desc: "Toggle Dock" },
                                        { key: "SUPER, L",     desc: "Lock Screen" },
                                        { key: "SUPER, ESC",   desc: "Open Power Menu" }
                                    ]
                                    delegate: Rectangle {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        implicitHeight: 40
                                        radius: 8
                                        color: "#14ffffff"
                                        border.color: "#18ffffff"
                                        border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 14; anchors.rightMargin: 14
                                            Text {
                                                text: modelData.desc
                                                color: Theme.text
                                                font.pixelSize: 13
                                                Layout.fillWidth: true
                                            }
                                            Rectangle {
                                                implicitWidth: shortcutBadge.implicitWidth + 14
                                                implicitHeight: 24
                                                radius: 4
                                                color: "#22ffffff"
                                                Text {
                                                    id: shortcutBadge
                                                    anchors.centerIn: parent
                                                    text: modelData.key
                                                    color: win.themeStore.accentColor
                                                    font.pixelSize: 11
                                                    font.family: "JetBrains Mono"
                                                    font.weight: Font.Bold
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // ===================================================
                            // TAB 6: PERFORMANCE
                            // ===================================================
                            ColumnLayout {
                                visible: win.currentTab === "performance"
                                Layout.fillWidth: true
                                spacing: 18

                                Text { text: "Performance Indicators & Polling"; color: Theme.text; font.pixelSize: 14; font.weight: Font.Bold }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "Poll Interval (" + win.themeStore.metricsInterval.toFixed(1) + " s)"
                                        color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold
                                        Layout.preferredWidth: 200
                                    }
                                    Slider {
                                        Layout.fillWidth: true
                                        from: 0.5; to: 4.0; stepSize: 0.5
                                        value: win.themeStore.metricsInterval
                                        onMoved: win.themeStore.saveSetting("", "metrics_interval", value)
                                    }
                                }
                            }

                            // ===================================================
                            // TAB 7: DISPLAYS
                            // ===================================================
                            ColumnLayout {
                                visible: win.currentTab === "displays"
                                Layout.fillWidth: true
                                spacing: 14

                                Text { text: "Active Monitors & Layer-Shell"; color: Theme.text; font.pixelSize: 14; font.weight: Font.Bold }

                                Repeater {
                                    model: Quickshell.screens
                                    delegate: Rectangle {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        implicitHeight: 56
                                        radius: 10
                                        color: "#14ffffff"
                                        border.color: "#18ffffff"
                                        border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 16; anchors.rightMargin: 16
                                            ColumnLayout {
                                                Text { text: modelData.name; color: win.themeStore.accentColor; font.pixelSize: 14; font.weight: Font.Bold }
                                                Text { text: modelData.width + "x" + modelData.height; color: Theme.muted; font.pixelSize: 11 }
                                            }
                                            Item { Layout.fillWidth: true }
                                            Rectangle {
                                                implicitWidth: 70; implicitHeight: 24
                                                radius: 4
                                                color: "#22ffffff"
                                                Text { anchors.centerIn: parent; text: "PRIMARY"; color: Theme.text; font.pixelSize: 9; font.weight: Font.Bold }
                                            }
                                        }
                                    }
                                }
                            }

                            // ===================================================
                            // TAB 8: ABOUT
                            // ===================================================
                            ColumnLayout {
                                visible: win.currentTab === "about"
                                Layout.fillWidth: true
                                spacing: 14

                                Text { text: "Levish Shell"; color: win.themeStore.accentColor; font.pixelSize: 20; font.weight: Font.Bold }
                                Text { text: "Version 1.0.0 — Leviathan OS Desktop Experience"; color: Theme.text; font.pixelSize: 13 }
                                Text { text: "Runtime: Quickshell · Qt 6 · QML · Hyprland IPC · Python Backend"; color: Theme.muted; font.pixelSize: 12 }
                                Text { text: "Levish is designed for high-performance, daily-driver desktop computing."; color: Theme.muted; font.pixelSize: 12 }
                            }
                        }
                    }
                }
            }
        }
    }
}
