// One setting: label and optional hint on the left, its control on the right.
import QtQuick
import QtQuick.Layouts
import "../../common/Theme.js" as Theme

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
            color: Theme.text
            font.pixelSize: 13
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }
        Text {
            visible: row.hint !== ""
            text: row.hint
            color: Theme.muted
            font.pixelSize: 11
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
