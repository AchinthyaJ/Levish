import QtQuick

// Circular gauge: a full neutral track with only the usage arc colored.
// The arc eases to its new value, so changes sweep instead of jumping.
Item {
    id: ring
    property real value: 0          // 0..100
    property color arcColor: "white"
    property real thickness: 5
    property string label: ""
    property string caption: ""

    implicitWidth: 64
    implicitHeight: 64

    property real shown: value
    Behavior on shown { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
    onShownChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const cx = width / 2, cy = height / 2
            const r = Math.min(width, height) / 2 - ring.thickness / 2 - 1
            ctx.lineCap = "round"
            ctx.lineWidth = ring.thickness
            ctx.strokeStyle = "rgba(255,255,255,0.20)"
            ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.stroke()
            ctx.strokeStyle = ring.arcColor
            ctx.beginPath()
            ctx.arc(cx, cy, r, -Math.PI / 2,
                    -Math.PI / 2 + Math.PI * 2 * Math.min(100, Math.max(0, ring.shown)) / 100)
            ctx.stroke()
        }
    }
    Column {
        anchors.centerIn: parent
        spacing: 0
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: ring.label; color: "#f5f9fd"
            font.family: "JetBrains Mono"; font.pixelSize: 13; font.weight: Font.DemiBold
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: ring.caption; color: "#9fb0c6"; font.pixelSize: 9
            visible: ring.caption !== ""
        }
    }
}
