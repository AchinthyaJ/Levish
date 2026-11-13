// Slim slider: a 4px track that fills in the accent, a small thumb that
// appears on hover, and a value readout. Emits moved(v) while dragging.
import QtQuick
import QtQuick.Layouts
import "../common" as C
import "../common/Theme.js" as Theme

ColumnLayout {
    id: s
    property string kind: ""      // Icon kind shown beside the label
    property string label: ""
    property real value: 0        // 0..100
    property real lo: 0           // lowest selectable value
    property bool muted: false
    signal moved(real v)

    readonly property real frac: Math.max(0, Math.min(1, (value - lo) / (100 - lo)))

    spacing: 9
    Layout.fillWidth: true

    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        C.Icon { kind: s.kind; tint: s.muted ? Theme.muted : Theme.text; width: 16; height: 16 }
        Text { text: s.label; color: Theme.text; font.pixelSize: 12; font.weight: Font.Medium; Layout.fillWidth: true }
        Text {
            text: s.muted ? "Muted" : Math.round(s.value) + "%"
            color: Theme.muted; font.pixelSize: 11; font.family: "JetBrains Mono"
        }
    }

    Item {
        Layout.fillWidth: true
        implicitHeight: 18

        Rectangle {
            id: track
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width; height: 4; radius: 2
            color: "#1affffff"
            Rectangle {
                width: parent.width * s.frac
                height: parent.height; radius: 2
                color: s.muted ? Theme.muted : Theme.accent
                Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            }
        }
        Rectangle {
            id: knob
            width: 12; height: 12; radius: 6
            color: Theme.text
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(0, Math.min(track.width - width, track.width * s.frac - width / 2))
            opacity: ma.containsMouse || ma.pressed ? 1 : 0
            scale: ma.pressed ? 1.2 : 1
            Behavior on opacity { NumberAnimation { duration: 150 } }
            Behavior on scale { NumberAnimation { duration: 100 } }
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            function emit(mx) {
                const p = Math.max(0, Math.min(1, mx / width))
                s.moved(Math.round(s.lo + p * (100 - s.lo)))
            }
            onPositionChanged: (m) => { if (pressed) emit(m.x) }
            onClicked:         (m) => emit(m.x)
        }
    }
}
