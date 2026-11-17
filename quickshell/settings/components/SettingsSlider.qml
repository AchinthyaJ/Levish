// Drag slider. While dragging it previews locally; the value is committed once on release,
// so dragging does not rewrite config.json on every pixel.
import QtQuick
import "../../common/Theme.js" as Theme
import "../../common" as Pal

Item {
    id: s
    property real from: 0
    property real to: 100
    property real step: 1
    property real value: 0
    property color accent: Pal.Palette.accent
    property string suffix: ""
    property int decimals: 0
    signal committed(real value)

    // 240 px when there is room, shrinking with the row on narrow windows.
    width: Math.max(120, Math.min(240, parent ? parent.width : 240)); height: 30

    // `live` follows `value` and previews a drag without breaking the binding to the config value.
    property real live: value
    onValueChanged: live = value
    readonly property real frac: to === from ? 0 : Math.max(0, Math.min(1, (live - from) / (to - from)))
    function snap(v) {
        const n = Math.round((v - from) / step) * step + from
        return Math.max(from, Math.min(to, n))
    }
    function display(v) { return decimals > 0 ? v.toFixed(decimals) : Math.round(v).toString() }

    Rectangle {
        id: track
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        height: 4; radius: 2
        color: Pal.Palette.controlEdge
        Rectangle {
            width: parent.width * s.frac
            height: parent.height; radius: 2
            color: s.accent
        }
    }
    Rectangle {
        width: 14; height: 14; radius: 7
        color: Pal.Palette.textPrimary
        x: track.width * s.frac - width / 2
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        anchors { right: parent.right; top: parent.bottom; topMargin: 2 }
        text: s.display(s.live) + s.suffix
        color: Pal.Palette.muted
        font.pixelSize: Theme.fs(10)
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function setFrom(mx) {
            const raw = s.from + (Math.max(0, Math.min(track.width, mx - track.x)) / track.width) * (s.to - s.from)
            s.live = s.snap(raw)
        }
        onPressed: (m) => setFrom(m.x)
        onPositionChanged: (m) => { if (pressed) setFrom(m.x) }
        onReleased: s.committed(s.live)
    }
}
