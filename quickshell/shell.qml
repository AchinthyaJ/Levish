//@ pragma UseQApplication
// Levish — Quickshell root. Unified Top Bar + performance panel + control center + power menu + dock + launcher + settings.
// UseQApplication lets tray items open their native menus (SystemTrayItem.display needs it).
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "common"
import "common" as Pal
import "bar"
import "dashboard"
import "controls"
import "dock"
import "launcher"
import "settings"
import "wallpaper"
import "notifications"
import "osd"
import "clipboard"
import "hypr"
import "session"
import "lock"
import "audio"

ShellRoot {
    id: root

    ThemeStore { id: themeStore }
    AudioService { id: audioService }
    // The colour palette reads its values from this store. Set through the alias import: the bare
    // name does not reach the singleton from this file.
    Component.onCompleted: Pal.Palette.store = themeStore
    readonly property var themeStoreObj: themeStore
    Data { id: dataStore }
    readonly property var store: dataStore

    // ── Application dock: one instance, shared by every dock window ──
    DockSettings { id: dockSettings; themeStore: root.themeStoreObj }
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
                themeStore: root.themeStoreObj
                screen: modelData
                dockState: root.dockState
                open: root.launcherOpen && modelData === dockSettings.targetScreens[0]
                onCloseRequested: root.launcherOpen = false
            }
        }
    }

    // ── Keyboard shortcuts ─────────────────────────────────────────────
    // Hyprland binds call scripts/levish-ipc.sh, which calls these functions:
    //   qs -p <quickshell dir> ipc call levish <function>
    IpcHandler {
        target: "levish"

        function toggleLauncher() { root.launcherOpen = !root.launcherOpen }
        function toggleControlCenter() {
            root.powerOpen = false
            root.settingsOpen = false
            root.ccOpen = !root.ccOpen
        }
        function togglePerformance() { root.panelState = !root.panelState }
        function togglePowerMenu() {
            root.ccOpen = false
            root.settingsOpen = false
            root.powerOpen = !root.powerOpen
        }
        function toggleSettings() {
            root.ccOpen = false
            root.powerOpen = false
            root.settingsOpen = !root.settingsOpen
        }
        // Persisted: showing or hiding the dock is a configuration change, like in Settings.
        function toggleDock() { themeStore.set("dock.enabled", !themeStore.dockEnabled) }
        // Used by the Settings wallpaper page and by scripts: sets the wallpaper image path.
        function setWallpaper(path) { themeStore.set("wallpaper.path", path) }
        function setWallpaperFit(fit) { themeStore.set("wallpaper.fit", fit) }
        function toggleWallpaperRotate() { themeStore.set("wallpaper.auto_rotate", !themeStore.wallpaperAutoRotate) }
        // Read-only status for scripts and debugging: config state and the active wallpaper path.
        function wallpaperStatus() { return themeStore.status + " " + themeStore.wallpaperPath + " (" + themeStore.wallpaperFit + ")" }
        function lock() { lockService.lockNow() }
        function unlock() { lockService.unlock() }
        function isLocked() { return lockService.isLocked }
        // Keyboard brightness keys (XF86MonBrightnessUp / Down): one 5 % step each.
        function brightnessUp() { root.adjustBrightness(5) }
        function brightnessDown() { root.adjustBrightness(-5) }
    }

    // ── Notifications: one server for the session, one popup window ──
    NotificationService { id: notifications; themeStore: root.themeStoreObj }

    // ── Clipboard history (text, in memory, opt-in in Settings) ──
    ClipboardService { id: clipboardHistory; themeStore: root.themeStoreObj }

    // Read-only Hyprland queries (keybinds, monitors) for the Keyboard and Displays pages.
    HyprQuery { id: hyprQuery }

    // Night light (hyprsunset) and caffeine (idle inhibitor).
    SessionTools { id: sessionTools; themeStore: root.themeStoreObj }

    // Lock screen (hyprlock look) and idle locking (hypridle).
    LockService { id: lockService; themeStore: root.themeStoreObj; store: root.store }

    NotificationPopups { service: notifications; themeStore: root.themeStoreObj }

    // ── On-screen display: volume, brightness and keyboard layout ──
    Osd { themeStore: root.themeStoreObj }

    // Settings window overlay
    SettingsWindow {
        themeStore: root.themeStoreObj
        notifications: notifications
        clipboard: clipboardHistory
        hypr: hyprQuery
        session: sessionTools
        lock: lockService
        audio: audioService
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

    // ── Control socket sender for power menu, shell actions and keys ──
    // Commands go out one at a time, in order. Nothing is dropped while one is in flight:
    // brightness steps are relative, so a key press that was queued must still be sent.
    Process {
        id: ctrlProc
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onRunningChanged: if (!running) root.pumpControl()
    }

    property var controlQueue: []

    function pumpControl() {
        if (ctrlProc.running || controlQueue.length === 0) return
        const json = controlQueue[0]
        controlQueue = controlQueue.slice(1)
        const script = "import socket,sys; s=socket.socket(socket.AF_UNIX); s.connect('/tmp/levish/control.sock'); s.sendall(sys.argv[1].encode()); s.shutdown(socket.SHUT_WR); print(s.recv(4096).decode())"
        ctrlProc.command = ["python3", "-c", script, json]
        ctrlProc.running = true
    }

    function sendControl(payload) {
        controlQueue = controlQueue.concat([JSON.stringify(payload)])
        pumpControl()
    }

    function sendAction(act) {
        if (act === "lock") {
            lockService.lockNow()
            return
        }
        sendControl({ cmd: "action", action: act })
    }

    // Keyboard brightness: a relative step handled by the backend (brightnessctl), which clamps 1–100 %.
    function adjustBrightness(delta) {
        sendControl({ cmd: "action", action: "adjust_brightness", value: delta })
    }

    // Wallpaper: applied through hyprpaper whenever the chosen path changes.
    WallpaperService { themeStore: root.themeStoreObj }

    // One scope per screen: the unified top bar and the drop-downs that grow out of it
    Variants {
        model: Quickshell.screens
        delegate: Scope {
            id: monitor
            required property var modelData

            Wallpaper {
                screen: monitor.modelData
                themeStore: root.themeStoreObj
            }

            Bar {
                id: bar
                screen: monitor.modelData
                store: root.store
                onTrayMenuRequested: (item, x) => trayMenu.openFor(item, x)
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
                floating: bar.islands
                barHeight: bar.implicitHeight   // islands fill the window, so this is their bottom edge
                open: root.panelState
                onHoveredChanged: root.overPanel = hovered
            }

            ControlCenter {
                screen: monitor.modelData
                store: root.store
                anchorRight: bar.statusRight
                anchorWidth: bar.statusWidth
                floating: bar.islands
                barHeight: bar.implicitHeight   // islands fill the window, so this is their bottom edge
                open: root.ccOpen
                onCloseRequested: root.ccOpen = false
                onSettingsRequested: {
                    root.ccOpen = false
                    root.settingsOpen = true
                }
            }

            // Styled context menu for tray apps (one per screen, opened by the bar).
            TrayMenu { id: trayMenu; screen: monitor.modelData }

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
