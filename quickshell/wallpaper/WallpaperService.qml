// WallpaperService — Discovers and applies wallpapers through hyprpaper for Hyprland.
// Scans system and user wallpaper directories, supports instant live selection,
// fit modes (cover, contain, fill, tile), auto-rotation timer, and persistent hyprpaper configuration.
import QtQuick
import Quickshell
import Quickshell.Io
import "WallpaperPaths.js" as Paths

Item {
    id: svc
    required property var themeStore

    readonly property string path: (themeStore && themeStore.wallpaperPath && themeStore.wallpaperPath.length > 0)
                                   ? themeStore.wallpaperPath
                                   : "/usr/share/hypr/wall0.png"
    readonly property string fitMode: (themeStore && themeStore.wallpaperFit) ? themeStore.wallpaperFit : "cover"
    readonly property string customFolder: (themeStore && themeStore.wallpaperFolder) ? themeStore.wallpaperFolder.trim() : ""

    property var wallpapers: []
    property int currentIndex: 0

    readonly property string home: Quickshell.env("HOME") || ""
    readonly property string confFile: Paths.stateDir(Quickshell.env("XDG_STATE_HOME"), home) + "/hyprpaper.conf"
    readonly property string logFile: Paths.stateDir(Quickshell.env("XDG_STATE_HOME"), home) + "/hyprpaper.log"

    // Writes Levish's own hyprpaper config and restarts hyprpaper with it. The user's
    // ~/.config/hypr/hyprpaper.conf is never touched.
    function apply() {
        if (!svc.path || svc.path.trim() === "") return
        applyProc.running = false
        applyProc.command = Paths.applyCommand(svc.path.trim(), svc.fitMode, svc.confFile, svc.logFile)
        applyProc.running = true
    }

    function scan() {
        const xdgPictures = Quickshell.env("XDG_PICTURES_DIR") || ""
        scanProc.running = false
        scanProc.command = Paths.scanCommand(Paths.scanRoots(svc.home, xdgPictures, svc.customFolder))
        scanProc.running = true
    }

    function randomize() {
        if (svc.wallpapers.length > 0) {
            const idx = Math.floor(Math.random() * svc.wallpapers.length)
            svc.currentIndex = idx
            const pick = svc.wallpapers[idx]
            if (svc.themeStore) {
                svc.themeStore.set("wallpaper.path", pick)
            }
        }
    }

    onPathChanged: apply()
    onFitModeChanged: apply()
    onCustomFolderChanged: scan()

    Component.onCompleted: {
        scan()
        apply()
    }

    // Process to discover image files across standard background locations
    Process {
        id: scanProc
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n").filter(p => p.length > 0)
                if (lines.length > 0) {
                    svc.wallpapers = lines
                    if (svc.themeStore && svc.themeStore.setWallpaperList) {
                        svc.themeStore.setWallpaperList(lines)
                    }
                }
            }
        }
    }

    // Auto-rotate timer
    Timer {
        id: rotateTimer
        interval: Math.max(30, (svc.themeStore && svc.themeStore.wallpaperInterval ? svc.themeStore.wallpaperInterval : 1800)) * 1000
        running: (svc.themeStore && svc.themeStore.wallpaperAutoRotate === true)
        repeat: true
        onTriggered: {
            if (svc.wallpapers.length > 1) {
                svc.currentIndex = (svc.currentIndex + 1) % svc.wallpapers.length
                const nextWallpaper = svc.wallpapers[svc.currentIndex]
                if (svc.themeStore) {
                    svc.themeStore.set("wallpaper.path", nextWallpaper)
                }
            }
        }
    }

    Process {
        id: applyProc
        stderr: StdioCollector { id: applyErr }
        onExited: (code) => {
            if (code !== 0) console.warn("wallpaper: hyprpaper apply exited with: " + code + " " + applyErr.text)
        }
    }
}
