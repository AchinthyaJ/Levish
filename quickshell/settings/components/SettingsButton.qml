// Plain or danger button used for page actions.
import QtQuick
import "../../common/Theme.js" as Theme
import "../../common" as Pal

Rectangle {
    id: b
    property string text: ""
    property bool danger: false
    signal clicked()

    implicitWidth: label.implicitWidth + 28
    height: 30; radius: 9
    color: ma.containsMouse ? (danger ? Theme.dangerEdge : Pal.Palette.controlEdge) : Pal.Palette.controlFill
    border.color: danger ? Theme.dangerEdge : Pal.Palette.controlEdge
    border.width: 1

    Text {
        id: label
        anchors.centerIn: parent
        text: b.text
        color: b.danger ? Pal.Palette.danger : Pal.Palette.text
        font.pixelSize: Theme.fs(12)
        font.weight: Font.Medium
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: b.clicked()
    }
}
