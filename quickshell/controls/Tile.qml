// Quick-settings tile: a rounded card with a round icon badge, a title and a
// status line. Checked tiles light up in the accent; clicking emits toggled().
import QtQuick
import QtQuick.Layouts
import "../common" as C
import "../common/Theme.js" as Theme

Rectangle {
    id: tile
    property string kind: ""
    property string title: ""
    property string subtitle: ""
    property bool checked: false
    signal toggled()

    Layout.fillWidth: true
    implicitHeight: 66
    radius: 22
    color: checked ? "#24c8f7ef" : (ma.containsMouse ? "#1affffff" : "#12ffffff")
    border.width: 1
    border.color: checked ? "#40c8f7ef" : "#14ffffff"
    Behavior on color { ColorAnimation { duration: 180 } }
    Behavior on border.color { ColorAnimation { duration: 180 } }

    RowLayout {
        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
        spacing: 10

        Rectangle {
            Layout.preferredWidth: 36; Layout.preferredHeight: 36
            radius: 18
            color: tile.checked ? Theme.accent : "#18ffffff"
            Behavior on color { ColorAnimation { duration: 180 } }
            C.Icon {
                anchors.centerIn: parent
                width: 17; height: 17
                kind: tile.kind
                tint: tile.checked ? Theme.solidPanel : Theme.text
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Text {
                text: tile.title; color: Theme.text
                font.pixelSize: 13; font.weight: Font.DemiBold
                elide: Text.ElideRight; Layout.fillWidth: true
            }
            Text {
                text: tile.subtitle; color: Theme.muted
                font.pixelSize: 10
                elide: Text.ElideRight; Layout.fillWidth: true
            }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.toggled()
    }
}
