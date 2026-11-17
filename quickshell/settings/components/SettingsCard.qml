// A titled group of settings rows on one translucent card.
import QtQuick
import QtQuick.Layouts
import "../../common/Theme.js" as Theme
import "../../common" as Pal

Rectangle {
    id: card
    property string title: ""
    default property alias content: body.data

    Layout.fillWidth: true
    implicitHeight: body.implicitHeight + 32
    radius: 14
    color: Pal.Palette.surface
    border.color: Pal.Palette.surfaceEdge
    border.width: 1

    // A ColumnLayout, not a Column: children that set Layout.fillWidth (fields, lists) need the card width.
    ColumnLayout {
        id: body
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
        spacing: 12

        Text {
            visible: card.title !== ""
            text: card.title.toUpperCase()
            color: Pal.Palette.muted
            font.pixelSize: Theme.fs(10)
            font.weight: Font.DemiBold
            font.letterSpacing: 1.2
        }
    }
}
