// One floating island: layered glass fill, inner highlight, soft shadow,
// hover lift and an animated width so content changes flow smoothly.
// `flatBottom` squares off the bottom corners so a drop-down panel can hang
// from the island as one continuous surface.
import QtQuick
import "../common/Theme.js" as Theme

Item {
    id: island
    default property alias content: holder.data
    property bool hoverable: false
    property bool lift: true          // scale up slightly on hover (off for islands that drop a panel)
    property bool flatBottom: false   // square bottom corners while a panel hangs from the island
    property alias hovered: hover.containsMouse
    signal entered()
    signal exited()
    signal clicked()

    implicitWidth: holder.childrenRect.width + Theme.islandPad * 2
    implicitHeight: Theme.barHeight
    Behavior on implicitWidth { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

    // soft shadow (hidden while flat, since the panel takes over that edge)
    Rectangle {
        x: 0; y: 3
        width: island.width; height: island.height
        radius: Theme.radiusIsland
        color: "#22000000"
        visible: !island.flatBottom
        z: -1
    }

    // The clipper cuts the body at the island's bottom edge. When flat, the body
    // is extended by one radius below the cut, so its rounded corners fall outside
    // the clip and the visible bottom edge is square.
    Item {
        id: clipper
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: island.height
        clip: island.flatBottom

        Rectangle {
            id: body
            x: 0; y: 0
            width: clipper.width
            height: clipper.height + (island.flatBottom ? Theme.radiusIsland : 0)
            radius: Theme.radiusIsland
            color: Theme.glass
            border.color: island.hovered ? "#66ffffff" : Theme.glassEdge
            border.width: 1
            scale: island.hovered && island.hoverable && island.lift ? 1.02 : 1
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
            Behavior on border.color { ColorAnimation { duration: 180 } }
        }
    }

    Item {
        id: holder
        x: Theme.islandPad
        y: 0
        width: childrenRect.width
        height: island.height
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        onEntered: island.entered()
        onExited: island.exited()
        onClicked: island.clicked()
    }
}
