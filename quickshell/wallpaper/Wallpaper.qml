// Background wallpaper window. One layer-shell surface per monitor, anchored to fill
// the screen on the Background layer. It reads the wallpaper path from ThemeStore.
// Smoothly crossfades between wallpapers when selection changes.
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../common/Theme.js" as Theme

PanelWindow {
    id: win
    required property var screen
    required property var themeStore

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.namespace: "levish-wallpaper"
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    readonly property string wallpaperSource: {
        let p = themeStore ? themeStore.wallpaperPath : ""
        if (!p || p.trim() === "") p = "/usr/share/hypr/wall0.png"
        return p.startsWith("file://") ? p : ("file://" + encodeURI(p))
    }

    readonly property string fitMode: (themeStore && themeStore.wallpaperFit) ? themeStore.wallpaperFit : "cover"

    readonly property int imageFillMode: {
        if (win.fitMode === "contain") return Image.PreserveAspectFit
        if (win.fitMode === "tile") return Image.Tile
        if (win.fitMode === "stretch") return Image.Stretch
        return Image.PreserveAspectCrop
    }

    property string activeSource: win.wallpaperSource
    property string pendingSource: ""

    // Base background layer
    Image {
        id: bgUnder
        anchors.fill: parent
        source: win.activeSource
        fillMode: win.imageFillMode
        asynchronous: true
        smooth: true
        mipmap: true
        visible: status === Image.Ready
    }

    // Overlay transition layer for buttery-smooth cross-fading
    Image {
        id: bgOver
        anchors.fill: parent
        source: win.pendingSource
        fillMode: win.imageFillMode
        asynchronous: true
        smooth: true
        mipmap: true
        opacity: 0

        onStatusChanged: {
            if (status === Image.Ready && win.pendingSource !== "") {
                fadeAnim.restart()
            }
        }
    }

    NumberAnimation {
        id: fadeAnim
        target: bgOver
        property: "opacity"
        from: 0
        to: 1
        duration: Theme.dur(300)
        easing.type: Easing.InOutQuad
        onFinished: {
            win.activeSource = win.pendingSource
            bgOver.opacity = 0
            win.pendingSource = ""
        }
    }

    onWallpaperSourceChanged: {
        if (wallpaperSource !== activeSource) {
            pendingSource = wallpaperSource
        }
    }
}
