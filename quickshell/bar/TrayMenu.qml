// Context menu for tray apps, drawn in Levish's glass style under the clicked icon.
// A press anywhere outside the menu closes it. Choosing an item closes it too.
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../common/Theme.js" as Theme

Scope {
    id: root
    required property var screen       // the monitor this menu appears on

    property var item: null            // SystemTrayItem whose menu is open
    property real anchorX: 0           // centre of the clicked icon, in bar coordinates
    property int barOffset: 46         // just below the top bar
    readonly property bool open: item !== null

    function openFor(trayItem, x) {
        item = trayItem
        anchorX = x
    }

    function close() { item = null }

    // Click catcher: sits under the menu and closes it on any press outside.
    PanelWindow {
        screen: root.screen
        visible: root.open
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.namespace: "levish-tray-catch"
        // Top, not Overlay: the menu is on Overlay, so its items always receive the click.
        // On the same layer the catcher could take the press first and close the menu.
        WlrLayershell.layer: WlrLayer.Top
        anchors { top: true; bottom: true; left: true; right: true }
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: root.close()
        }
    }

    PanelWindow {
        id: menuWin
        screen: root.screen
        visible: root.open
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.namespace: "levish-tray-menu"
        WlrLayershell.layer: WlrLayer.Overlay
        anchors { top: true; left: true }
        margins {
            top: root.barOffset
            left: Math.max(8, Math.min(root.anchorX - card.width / 2, root.screen.width - card.width - 8))
        }
        implicitWidth: card.width
        implicitHeight: card.height

        Rectangle {
            id: card
            width: 264
            height: menuCol.implicitHeight + 16
            radius: 14
            color: Theme.glass
            border.color: Theme.glassEdge
            border.width: 1

            Column {
                id: menuCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
                TrayMenuEntries {
                    width: parent.width
                    menu: root.item ? root.item.menu : null
                    onDone: root.close()
                }
            }
        }
    }
}
