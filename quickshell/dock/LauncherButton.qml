// Launcher cell. It opens the existing Levish launcher; no second launcher is built.
// Distinct by shape and glyph, not by a bright accent: a rounded tile with the grid symbol.
import QtQuick
import "../common" as C
import "../common/Theme.js" as Theme

Item {
    id: btn

    required property var dockState   // DockModel
    required property int iconSize

    width: iconSize + Theme.dockCellPad
    height: iconSize + 14

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: 14
        color: hover.containsMouse ? Theme.dockHover : "transparent"
        Behavior on color { ColorAnimation { duration: 160 } }
    }

    Rectangle {
        id: tile
        width: btn.iconSize * 0.9
        height: btn.iconSize * 0.9
        x: (btn.width - width) / 2
        y: 4 + (btn.iconSize - height) / 2
        radius: width * 0.3
        color: hover.containsMouse ? "#26ffffff" : "#16ffffff"
        border.color: Theme.dockEdge
        border.width: 1
        transformOrigin: Item.Bottom
        scale: hover.containsMouse ? Theme.dockZoom : 1
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 160 } }

        C.Icon {
            anchors.centerIn: parent
            width: tile.width * 0.5
            height: tile.height * 0.5
            kind: "apps"
            tint: Theme.text
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.dockState.openLauncher()
    }
}
