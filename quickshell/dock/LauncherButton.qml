// Launcher cell. It opens the existing Levish launcher; no second launcher is built.
// Distinct by shape and glyph, not by a bright accent: a rounded tile with the grid symbol.
import QtQuick
import "../common" as C
import "../common/Theme.js" as Theme
import "../common" as Pal

Item {
    id: btn

    required property var dockState   // DockModel
    required property int iconSize
    property real zoom: Theme.dockZoom
    property string side: "bottom"

    readonly property bool vertical: side === "left" || side === "right"
    width: vertical ? iconSize + 14 : iconSize + Theme.dockCellPad
    height: vertical ? iconSize + Theme.dockCellPad : iconSize + 14

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: 14
        color: hover.containsMouse ? Pal.Palette.dockHover : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.dur(160) } }
    }

    Rectangle {
        id: tile
        width: btn.iconSize * 0.9
        height: btn.iconSize * 0.9
        x: btn.vertical ? 4 + (btn.iconSize - width) / 2 : (btn.width - width) / 2
        y: btn.vertical ? (btn.height - height) / 2 : 4 + (btn.iconSize - height) / 2
        radius: width * 0.3
        color: hover.containsMouse ? Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.149) : Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.086)
        border.color: Pal.Palette.dockEdge
        border.width: 1
        transformOrigin: Item.Center
        scale: hover.containsMouse ? zoom : 1
        Behavior on scale { NumberAnimation { duration: Theme.dur(180); easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: Theme.dur(160) } }

        C.Icon {
            anchors.centerIn: parent
            width: tile.width * 0.5
            height: tile.height * 0.5
            kind: "apps"
            tint: Pal.Palette.text
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
