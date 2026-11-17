// On/off switch. Commits on click; the value is always the one the config service reports.
import QtQuick
import "../../common/Theme.js" as Theme
import "../../common" as Pal

Rectangle {
    id: sw
    property bool checked: false
    property color accent: Pal.Palette.accent
    signal toggled(bool value)

    width: 44; height: 24; radius: 12
    color: checked ? Qt.rgba(accent.r, accent.g, accent.b, 0.85) : Pal.Palette.controlEdge
    border.color: checked ? accent : Pal.Palette.controlEdge
    border.width: 1
    Behavior on color { ColorAnimation { duration: Theme.dur(120) } }

    Rectangle {
        width: 18; height: 18; radius: 9
        y: 3
        x: sw.checked ? sw.width - width - 3 : 3
        color: Pal.Palette.textPrimary
        Behavior on x { NumberAnimation { duration: Theme.dur(120); easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: sw.toggled(!sw.checked)
    }
}
