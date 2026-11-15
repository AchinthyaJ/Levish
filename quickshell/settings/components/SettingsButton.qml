// Plain or danger button used for page actions.
import QtQuick
import "../../common/Theme.js" as Theme

Rectangle {
    id: b
    property string text: ""
    property bool danger: false
    signal clicked()

    implicitWidth: label.implicitWidth + 28
    height: 30; radius: 9
    color: ma.containsMouse ? (danger ? Theme.dangerEdge : Theme.controlEdge) : Theme.controlFill
    border.color: danger ? Theme.dangerEdge : Theme.controlEdge
    border.width: 1

    Text {
        id: label
        anchors.centerIn: parent
        text: b.text
        color: b.danger ? Theme.danger : Theme.text
        font.pixelSize: 12
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
