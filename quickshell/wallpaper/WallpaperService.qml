// Applies the chosen wallpaper through hyprpaper, the Hyprland wallpaper daemon.
// The path comes from the config service (wallpaper.path). hyprpaper reads its wallpaper from a
// config file, so this writes /tmp/levish/hyprpaper.conf and restarts hyprpaper with it.
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: svc
    required property var themeStore

    readonly property string path: themeStore.wallpaperPath

    function apply() {
        if (svc.path === "") return
        // Path is passed as an argument, never spliced into the shell command.
        applyProc.command = ["sh", "-c",
            "mkdir -p /tmp/levish && "
            + "printf 'wallpaper {\\n    monitor =\\n    path = %s\\n    fit_mode = cover\\n}\\n\\nsplash = false\\n' \"$1\" > /tmp/levish/hyprpaper.conf && "
            + "pkill -x hyprpaper; sleep 0.3; "
            + "setsid hyprpaper -c /tmp/levish/hyprpaper.conf >/tmp/levish/hyprpaper.log 2>&1 &",
            "sh", svc.path]
        applyProc.running = true
    }

    onPathChanged: apply()
    Component.onCompleted: apply()

    Process {
        id: applyProc
        stderr: StdioCollector { id: applyErr }
        onExited: (code) => { if (code !== 0) console.warn("wallpaper: could not apply via hyprpaper: " + applyErr.text) }
    }
}
