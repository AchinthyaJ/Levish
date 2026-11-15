// A titled group of settings rows on one translucent card.
import QtQuick
import QtQuick.Layouts
import "../../common/Theme.js" as Theme

Rectangle {
    id: card
    property string title: ""
    default property alias content: body.data

    Layout.fillWidth: true
    implicitHeight: body.implicitHeight + 32
    radius: 14
    color: "#12ffffff"
    border.color: "#18ffffff"
    border.width: 1

    Column {
        id: body
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
        spacing: 12

        Text {
            visible: card.title !== ""
            text: card.title.toUpperCase()
            color: Theme.muted
            font.pixelSize: 10
            font.weight: Font.DemiBold
            font.letterSpacing: 1.2
        }
    }
}
