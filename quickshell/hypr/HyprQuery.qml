// Read-only queries to Hyprland for the Settings pages: keybinds and monitors.
// Runs `hyprctl … -j` on demand (when a page opens or Refresh is pressed). Nothing is changed.
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: svc

    property var binds: []         // parsed `hyprctl binds -j`
    property var monitors: []      // parsed `hyprctl monitors -j`
    // "idle" | "loading" | "ok" | "error"
    property string status: "idle"
    property string error: ""

    property int _pending: 0

    function refresh() {
        svc.status = "loading"
        svc.error = ""
        svc._pending = 2
        bindsProc.running = false
        monProc.running = false
        bindsProc.running = true
        monProc.running = true
    }

    function _done(failed, message) {
        if (failed) {
            svc.error = message
            svc.status = "error"
        }
        svc._pending -= 1
        if (svc._pending <= 0 && svc.status !== "error") svc.status = "ok"
    }

    Process {
        id: bindsProc
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector { id: bindsOut }
        onExited: (code) => {
            let parsed = null
            try { parsed = JSON.parse(bindsOut.text) } catch (e) { parsed = null }
            if (code !== 0 || !Array.isArray(parsed)) {
                svc._done(true, "Could not read keybinds from Hyprland (is Hyprland running?)")
                return
            }
            svc.binds = parsed
            svc._done(false, "")
        }
    }

    Process {
        id: monProc
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector { id: monOut }
        onExited: (code) => {
            let parsed = null
            try { parsed = JSON.parse(monOut.text) } catch (e) { parsed = null }
            if (code !== 0 || !Array.isArray(parsed)) {
                svc._done(true, "Could not read monitors from Hyprland (is Hyprland running?)")
                return
            }
            svc.monitors = parsed
            svc._done(false, "")
        }
    }

    Component.onCompleted: refresh()
}
