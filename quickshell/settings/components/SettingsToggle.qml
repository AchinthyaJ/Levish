// On/off switch. Commits on click; the value is always the one the config service reports.
import QtQuick
import "../../common/Theme.js" as Theme

Rectangle {
    id: sw
    property bool checked: false
    property color accent: Theme.accent
    signal toggled(bool value)

    width: 44; height: 24; radius: 12
    color: checked ? Qt.rgba(accent.r, accent.g, accent.b, 0.85) : Theme.controlEdge
    border.color: checked ? accent : Theme.controlEdge
    border.width: 1
    Behavior on color { ColorAnimation { duration: 120 } }

    Rectangle {
        width: 18; height: 18; radius: 9
        y: 3
        x: sw.checked ? sw.width - width - 3 : 3
        color: Theme.textPrimary
        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: sw.toggled(!sw.checked)
    }
}
