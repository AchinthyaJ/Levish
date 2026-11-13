// Levish — Quickshell root. Bar + performance panel + control center.
import QtQuick
import Quickshell
import Quickshell.Io
import "common"
import "bar"
import "dashboard"
import "controls"

ShellRoot {
    id: root

    Data { id: dataStore }
    readonly property var store: dataStore

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
            }
        }
    }
}
