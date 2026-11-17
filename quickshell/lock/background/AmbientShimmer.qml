import QtQuick
import "../../common" as Pal

Item {
    id: root

    property color accent: Pal.Palette.accent
    property bool active: true
    property bool reducedMotion: false

    anchors.fill: parent
    clip: true

    // Ambient glow 1: Top-left / center slow drift
    Rectangle {
        id: orb1
        width: Math.min(parent.width, parent.height) * 0.7
        height: width
        radius: width / 2
        x: root.width * 0.15
        y: root.height * 0.1
        opacity: root.reducedMotion ? 0.04 : 0.07

        gradient: Gradient {
            GradientStop { position: 0.0; color: root.accent }
            GradientStop { position: 0.4; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.25) }
            GradientStop { position: 1.0; color: "transparent" }
        }

        SequentialAnimation on x {
            running: root.active && !root.reducedMotion
            loops: Animation.Infinite
            NumberAnimation { to: root.width * 0.28; duration: 18000; easing.type: Easing.InOutSine }
            NumberAnimation { to: root.width * 0.15; duration: 18000; easing.type: Easing.InOutSine }
        }

        SequentialAnimation on y {
            running: root.active && !root.reducedMotion
            loops: Animation.Infinite
            NumberAnimation { to: root.height * 0.22; duration: 14000; easing.type: Easing.InOutSine }
            NumberAnimation { to: root.height * 0.1; duration: 14000; easing.type: Easing.InOutSine }
        }
    }

    // Ambient glow 2: Bottom-right slow drift (cooler cyan/blue)
    Rectangle {
        id: orb2
        width: Math.min(parent.width, parent.height) * 0.8
        height: width
        radius: width / 2
        x: root.width * 0.55
        y: root.height * 0.45
        opacity: root.reducedMotion ? 0.03 : 0.05

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#00f5d4" }
            GradientStop { position: 0.5; color: Qt.rgba(0, 245/255, 212/255, 0.15) }
            GradientStop { position: 1.0; color: "transparent" }
        }

        SequentialAnimation on x {
            running: root.active && !root.reducedMotion
            loops: Animation.Infinite
            NumberAnimation { to: root.width * 0.42; duration: 22000; easing.type: Easing.InOutSine }
            NumberAnimation { to: root.width * 0.55; duration: 22000; easing.type: Easing.InOutSine }
        }

        SequentialAnimation on y {
            running: root.active && !root.reducedMotion
            loops: Animation.Infinite
            NumberAnimation { to: root.height * 0.35; duration: 17000; easing.type: Easing.InOutSine }
            NumberAnimation { to: root.height * 0.45; duration: 17000; easing.type: Easing.InOutSine }
        }
    }

    // Gentle subtle stardust / particles (Canvas based, 12 particles, static or subtle drift)
    Canvas {
        id: particleCanvas
        anchors.fill: parent
        opacity: 0.35
        visible: !root.reducedMotion

        property var particles: [
            { x: 0.2, y: 0.25, r: 1.5, o: 0.4 },
            { x: 0.8, y: 0.2, r: 2.0, o: 0.3 },
            { x: 0.15, y: 0.7, r: 1.2, o: 0.35 },
            { x: 0.75, y: 0.75, r: 1.8, o: 0.45 },
            { x: 0.4, y: 0.15, r: 1.4, o: 0.3 },
            { x: 0.6, y: 0.85, r: 1.6, o: 0.25 },
            { x: 0.3, y: 0.8, r: 2.2, o: 0.35 },
            { x: 0.85, y: 0.45, r: 1.3, o: 0.4 }
        ]

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const w = width, h = height
            ctx.fillStyle = root.accent
            for (let i = 0; i < particles.length; i++) {
                const p = particles[i]
                ctx.globalAlpha = p.o
                ctx.beginPath()
                ctx.arc(p.x * w, p.y * h, p.r, 0, Math.PI * 2)
                ctx.fill()
            }
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }
}
