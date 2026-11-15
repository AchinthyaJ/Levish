// Levish — Quickshell root. Unified Top Bar + performance panel + control center + power menu + dock + launcher + settings.
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
import "settings"

ShellRoot {
    id: root

    ThemeStore { id: themeStore }
    readonly property var themeStoreObj: themeStore
    Data { id: dataStore }
    readonly property var store: dataStore

    // ── Application dock: one instance, shared by every dock window ──
    DockSettings { id: dockSettings }
    DockModel { id: dockModel; dockConfig: dockSettings }
    readonly property var dockConfig: dockSettings
    readonly property var dockState: dockModel
    property bool launcherOpen: false
    property bool powerOpen: false
    property bool settingsOpen: false

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

    // Settings window overlay
    SettingsWindow {
        themeStore: root.themeStoreObj
        open: root.settingsOpen
        onCloseRequested: root.settingsOpen = false
    }

    // ── Performance panel hover logic ────────────────────────────────
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

    // ── Control Center & Power Menu toggles ───────────────────────────
    property bool ccOpen: false

    // Close control center and power menu on window focus change
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if ((root.ccOpen || root.powerOpen) && (event.name === "activewindow" || event.name === "activewindowv2")) {
                root.ccOpen = false
                root.powerOpen = false
            }
        }
    }

    // ── Control socket sender for power menu and shell actions ────────
    Process {
        id: ctrlProc
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        property string _pending: ""
        property var _pendingCmd: []
        onRunningChanged: {
            if (!running && _pending !== "") {
                command = _pendingCmd
                _pending = ""
                running = true
            }
        }
    }

    function sendAction(act) {
        const json = JSON.stringify({ cmd: "action", action: act })
        const script = "import socket,sys; s=socket.socket(socket.AF_UNIX); s.connect('/tmp/levish/control.sock'); s.sendall(sys.argv[1].encode()); s.shutdown(socket.SHUT_WR); print(s.recv(4096).decode())"
        const cmd = ["python3", "-c", script, json]
        if (ctrlProc.running) {
            ctrlProc._pendingCmd = cmd
            ctrlProc._pending = json
        } else {
            ctrlProc.command = cmd
            ctrlProc.running = true
        }
    }

    // One scope per screen: the unified top bar and the drop-downs that grow out of it
    Variants {
        model: Quickshell.screens
        delegate: Scope {
            id: monitor
            required property var modelData

            Bar {
                id: bar
                screen: monitor.modelData
                store: root.store
                themeStore: root.themeStoreObj
                onPerfHovered: (v) => root.overIsland = v
                onStatusClicked: {
                    root.powerOpen = false
                    root.settingsOpen = false
                    root.ccOpen = !root.ccOpen
                }
                onPowerClicked: {
                    root.ccOpen = false
                    root.settingsOpen = false
                    root.powerOpen = !root.powerOpen
                }
                onSettingsClicked: {
                    root.ccOpen = false
                    root.powerOpen = false
                    root.settingsOpen = !root.settingsOpen
                }
                perfOpen: root.panelState
                statusOpen: root.ccOpen
                powerOpen: root.powerOpen
                settingsOpen: root.settingsOpen
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
                onSettingsRequested: {
                    root.ccOpen = false
                    root.settingsOpen = true
                }
            }

            PowerMenu {
                screen: monitor.modelData
                anchorRight: bar.powerRight
                anchorWidth: bar.powerWidth
                open: root.powerOpen
                onCloseRequested: root.powerOpen = false
                onActionTriggered: (act) => root.sendAction(act)
            }
        }
    }
}
