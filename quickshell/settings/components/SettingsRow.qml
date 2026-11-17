// One setting: label and optional hint on the left, its control on the right.
import QtQuick
import QtQuick.Layouts
import "../../common/Theme.js" as Theme
import "../../common" as Pal

RowLayout {
    id: row
    property string label: ""
    property string hint: ""
    default property alias control: holder.data

    Layout.fillWidth: true
    spacing: 16

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        Text {
            text: row.label
            color: Pal.Palette.text
            font.pixelSize: Theme.fs(13)
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }
        Text {
            visible: row.hint !== ""
            text: row.hint
            color: Pal.Palette.muted
            font.pixelSize: Theme.fs(11)
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }
    }

    Item {
        id: holder
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
    }
}
