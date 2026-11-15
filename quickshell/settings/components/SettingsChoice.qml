// Segmented choice: one of a fixed list of options.
import QtQuick
import "../../common/Theme.js" as Theme

Row {
    id: c
    property var options: []      // [{ value, label }]
    property var current
    property color accent: "#c8f7ef"
    signal picked(var value)
    spacing: 4

    Repeater {
        model: c.options
        delegate: Rectangle {
            required property var modelData
            readonly property bool selected: c.current === modelData.value
            height: 28
            width: Math.max(64, label.implicitWidth + 24)
            radius: 8
            color: selected ? Qt.rgba(c.accent.r, c.accent.g, c.accent.b, 0.22) : (ma.containsMouse ? "#18ffffff" : "#0cffffff")
            border.color: selected ? c.accent : "#1effffff"
            border.width: 1

            Text {
                id: label
                anchors.centerIn: parent
                text: modelData.label
                color: selected ? Theme.text : Theme.muted
                font.pixelSize: 12
                font.weight: selected ? Font.DemiBold : Font.Normal
            }
            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: c.picked(modelData.value)
            }
        }
    }
}
