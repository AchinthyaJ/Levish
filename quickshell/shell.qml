// Levish — Quickshell root. Bar + performance panel + control center.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "common"
import "bar"
import "dashboard"
import "controls"
import "dock"
import "launcher"

ShellRoot {
    id: root

    Data { id: dataStore }
    readonly property var store: dataStore

    // ── Application dock: one instance, shared by every dock window ──
    DockSettings { id: dockSettings }
    DockModel { id: dockModel; dockConfig: dockSettings }
    readonly property var dockConfig: dockSettings
    readonly property var dockState: dockModel
    property bool launcherOpen: false
    Connections {
        target: dockModel
        function onLauncherRequested() { root.launcherOpen = !root.launcherOpen }
    }

    Variants {
        model: dockSettings.targetScreens
        delegate: Scope {
            required property var modelData
            Dock {
                screen: modelData
                dockState: root.dockState
                dockConfig: root.dockConfig
            }
            Launcher {
                screen: modelData
                dockState: root.dockState
                open: root.launcherOpen && modelData === dockSettings.targetScreens[0]
                onCloseRequested: root.launcherOpen = false
            }
        }
    }

    // ── Performance panel hover logic ────────────────────────────────
    // Grace period: moving the pointer from the island into the panel
    // won't trigger a flicker-close.
    property bool overIsland: false
    property bool overPanel: false

    Timer {
        id: closeGrace
        interval: 260
        onTriggered: if (!root.overIsland && !root.overPanel) root.panelState = false
    }
    property bool panelState: false
    onOverIslandChanged: { if (overIsland) { closeGrace.stop(); panelState = true } else closeGrace.restart() }
    onOverPanelChanged:  { if (overPanel)  { closeGrace.stop(); panelState = true } else closeGrace.restart() }

    // ── Control Center toggle ────────────────────────────────────────
    property bool ccOpen: false

    // The control centre closes when another window takes focus.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (root.ccOpen && (event.name === "activewindow" || event.name === "activewindowv2"))
                root.ccOpen = false
        }
    }

    // One scope per screen: the bar and the two drop-downs that grow out of it.
    Variants {
        model: Quickshell.screens
        delegate: Scope {
            id: monitor
            required property var modelData

            Bar {
                id: bar
                screen: monitor.modelData
                store: root.store
                onPerfHovered: (v) => root.overIsland = v
                onStatusClicked: root.ccOpen = !root.ccOpen
                perfOpen: root.panelState
                statusOpen: root.ccOpen
            }

            PerfPanel {
                screen: monitor.modelData
                store: root.store
                anchorLeft: bar.perfLeft
                anchorWidth: bar.perfWidth
                open: root.panelState
                onHoveredChanged: root.overPanel = hovered
            }

            ControlCenter {
                screen: monitor.modelData
                store: root.store
                anchorRight: bar.statusRight
                anchorWidth: bar.statusWidth
                open: root.ccOpen
                onCloseRequested: root.ccOpen = false
            }
        }
    }
}
