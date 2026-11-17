import QtQuick
import QtQuick.Effects
import Quickshell
import "../../common" as Pal

Item {
    id: root

    required property var themeStore
    property var screen: null
    property bool active: true

    anchors.fill: parent

    readonly property string wallpaperSource: {
        if (!themeStore) return ""
        if (themeStore.lockUseDesktopWallpaper) {
            return themeStore.wallpaperPath || ""
        }
        return themeStore.lockCustomWallpaperPath || themeStore.wallpaperPath || ""
    }

    // Base background tone — deep Levish blue-grey
    Rectangle {
        anchors.fill: parent
        color: "#0d1017"
    }

    // Wallpaper surface with blur effect
    Item {
        id: wpContainer
        anchors.fill: parent

        Image {
            id: wpImage
            anchors.fill: parent
            source: root.wallpaperSource !== "" ? (root.wallpaperSource.startsWith("/") ? "file://" + root.wallpaperSource : root.wallpaperSource) : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            visible: true
        }

        layer.enabled: (root.themeStore && root.themeStore.lockBlur > 0)
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: (root.themeStore ? Math.min(1.0, root.themeStore.lockBlur / 64.0) : 0.5)
            blurMax: 64
            autoPaddingEnabled: false
        }
    }

    // Configurable dimming overlay
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.themeStore ? root.themeStore.lockDimming : 0.45
    }

    // Atmospheric Levish color tint gradient
    Rectangle {
        anchors.fill: parent
        opacity: 0.35
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0d141e" }
            GradientStop { position: 0.5; color: "#141c28" }
            GradientStop { position: 1.0; color: "#0b0e14" }
        }
    }

    // Subtle edge vignette
    Canvas {
        id: vignette
        anchors.fill: parent
        opacity: root.themeStore ? root.themeStore.lockVignette : 0.5
        visible: opacity > 0.01

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const w = width, h = height
            const cx = w / 2, cy = h / 2
            const r = Math.hypot(cx, cy)
            const grad = ctx.createRadialGradient(cx, cy, r * 0.35, cx, cy, r)
            grad.addColorStop(0, "rgba(0,0,0,0)")
            grad.addColorStop(0.7, "rgba(5,8,14,0.35)")
            grad.addColorStop(1, "rgba(2,4,8,0.85)")
            ctx.fillStyle = grad
            ctx.fillRect(0, 0, w, h)
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    // Dynamic ambient shimmer
    AmbientShimmer {
        accent: root.themeStore ? root.themeStore.accentColor : Pal.Palette.accent
        active: root.active && (root.themeStore ? root.themeStore.lockAmbientEffects : true)
        reducedMotion: root.themeStore ? root.themeStore.lockReducedMotion : false
    }
}
