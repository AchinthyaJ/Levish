// Volume / Brightness slider row: icon · label · value · track
import QtQuick
import QtQuick.Layouts
import "../common" as C
import "../common/Theme.js" as Theme
import "../common" as Pal

ColumnLayout {
    id: row
    property string icon: ""   // an Icon kind name, e.g. "volume"
    property string label: ""
    property real value: 0       // 0-100
    property real minValue: 0
    property real maxValue: 100
    property color trackColor: Pal.Palette.accent
    property bool muted: false   // dims icon when true
    signal moved(real v)

    spacing: 6
    Layout.fillWidth: true

    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        C.Icon {
            kind: row.icon
            tint: row.muted ? Pal.Palette.muted : row.trackColor
            width: 20; height: 20
            Layout.preferredWidth: 20
        }
        Text {
            text: row.label
            color: Pal.Palette.text
            font.pixelSize: Theme.fs(12); font.weight: Font.Medium
            Layout.fillWidth: true
        }
        Text {
            text: Math.round(row.value) + "%"
            color: Pal.Palette.muted
            font.pixelSize: Theme.fs(11); font.family: "JetBrains Mono"
            Layout.preferredWidth: 34
            horizontalAlignment: Text.AlignRight
        }
    }

    // Track
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 20

        Rectangle {
            id: track
            anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right }
            height: 5; radius: 3
            color: Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.133)

            Rectangle {
                width: Math.max(radius * 2,
                                track.width * Math.min(1, Math.max(0,
                                    (row.value - row.minValue) / (row.maxValue - row.minValue))))
                height: parent.height; radius: 3
                color: row.muted ? Pal.Palette.muted : row.trackColor
                Behavior on width { NumberAnimation { duration: Theme.dur(120); easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: Theme.dur(180) } }
            }

            // Thumb
            Rectangle {
                id: thumb
                width: 14; height: 14; radius: 7
                color: Pal.Palette.text
                anchors.verticalCenter: parent.verticalCenter
                x: Math.max(0, Math.min(track.width - width,
                               track.width * Math.min(1, Math.max(0,
                                   (row.value - row.minValue) / (row.maxValue - row.minValue))) - width / 2))
                scale: ma.pressed ? 1.25 : (ma.containsMouse ? 1.1 : 1)
                Behavior on scale { NumberAnimation { duration: Theme.dur(120) } }
            }
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPositionChanged: (mouse) => {
                if (pressed) {
                    const pct = Math.max(0, Math.min(1, mouse.x / width))
                    row.moved(row.minValue + pct * (row.maxValue - row.minValue))
                }
            }
            onClicked: (mouse) => {
                const pct = Math.max(0, Math.min(1, mouse.x / width))
                row.moved(row.minValue + pct * (row.maxValue - row.minValue))
            }
        }
    }
}
