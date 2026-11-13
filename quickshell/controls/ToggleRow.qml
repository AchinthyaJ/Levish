// A labelled icon row with a pill toggle on the right.
// Used for Wi-Fi, Bluetooth, etc.
import QtQuick
import QtQuick.Layouts
import "../common" as C
import "../common/Theme.js" as Theme

RowLayout {
    id: row
    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool checked: false
    property color iconColor: Theme.accent   // icon: an Icon kind name, e.g. "wifi"
    signal toggled()

    spacing: 12
    Layout.fillWidth: true

    // Icon glyph
    C.Icon {
        kind: row.icon
        tint: row.checked ? row.iconColor : Theme.muted
        width: 20; height: 20
        Layout.preferredWidth: 20
    }

    // Label column
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 1
        Text {
            text: row.title
            color: Theme.text
            font.pixelSize: 13; font.weight: Font.Medium
        }
        Text {
            text: row.subtitle
            color: Theme.muted
            font.pixelSize: 10
            visible: row.subtitle !== ""
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }

    // Pill toggle
    Rectangle {
        id: pill
        implicitWidth: 42; implicitHeight: 24
        radius: 12
        color: row.checked ? Theme.accent : "#33ffffff"
        Behavior on color { ColorAnimation { duration: 200 } }
        border.color: row.checked ? "transparent" : "#22ffffff"
        border.width: 1

        Rectangle {
            id: knob
            width: 18; height: 18; radius: 9
            anchors.verticalCenter: parent.verticalCenter
            x: row.checked ? parent.width - width - 3 : 3
            color: row.checked ? Theme.solidPanel : Theme.text
            Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: row.toggled()
        }
    }
}
