// Context menu for a dock application, drawn in Levish's glass style beside the clicked icon.
// Items come from the app's own desktop actions (New Window, New Private Window, ...), then a
// generic New Window when the app has none, then Quit for running apps and the pin toggle.
// A press anywhere outside the menu closes it. Choosing an item closes it too.
//
// The menu is a layer-shell window, so it is placed from the dock's geometry: the dock window is
// centred on its screen along the axis it does not anchor to, so its position on screen is known.
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../common/Theme.js" as Theme
import "../common" as Pal

Scope {
    id: root
    required property var dockWindow   // the Dock's PanelWindow
    required property var dockState    // DockModel
    required property var dockConfig   // DockSettings

    property var cell: null            // DockItem the menu belongs to; null when closed
    readonly property bool open: cell !== null
    readonly property string side: dockWindow.side
    readonly property bool vertical: side === "left" || side === "right"

    property var entry: null           // DesktopEntry of the app, or null when unknown
    property var windows: []           // open Hyprland toplevels of the app
    property bool pinned: false
    property var items: []             // rows to show: { label, run } or { sep: true }
    property point anchorPoint: Qt.point(0, 0)   // centre of the clicked cell, in dock-window coordinates

    function openFor(c) {
        cell = c
        entry = c.entry
        windows = c.windows.slice()
        pinned = c.pinnedIndex >= 0
        anchorPoint = c.mapToItem(null, c.width / 2, c.height / 2)
        items = buildItems()
    }

    function close() { cell = null }

    function choose(item) {
        close()
        item.run()
    }

    function buildItems() {
        const out = []
        const e = entry
        if (e) {
            let hasNewWindow = false
            const actions = e.actions
            for (let i = 0; i < actions.length; i++) {
                const a = actions[i]
                if (/new window/i.test(a.name)) hasNewWindow = true
                out.push({ label: a.name, run: () => a.execute() })
            }
            if (!hasNewWindow) out.push({ label: "New window", run: () => e.execute() })
        }
        if (out.length > 0) out.push({ sep: true })
        if (windows.length > 0) out.push({ label: "Quit", run: () => dockState.closeWindows(windows) })
        if (e) {
            out.push({
                label: pinned ? "Remove from dock" : "Keep in dock",
                run: () => dockState.togglePin(e)
            })
        }
        // Drop a trailing separator when the groups above it were empty.
        while (out.length > 0 && out[out.length - 1].sep) out.pop()
        return out
    }

    // Click catcher: sits under the menu and closes it on any press outside.
    PanelWindow {
        screen: root.dockWindow.screen
        visible: root.open
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.namespace: "levish-dock-catch"
        // Top, not Overlay: the menu is on Overlay, so its items always receive the click.
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
        screen: root.dockWindow.screen
        visible: root.open
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.namespace: "levish-dock-menu"
        WlrLayershell.layer: WlrLayer.Overlay

        readonly property real screenW: root.dockWindow.screen.width
        readonly property real screenH: root.dockWindow.screen.height
        // Where the dock window starts on screen, along the axis the compositor centres it on.
        readonly property real dockLeft: (screenW - root.dockWindow.width) / 2
        readonly property real dockTop: (screenH - root.dockWindow.height) / 2
        readonly property real along: root.vertical
            ? Math.max(8, Math.min(dockTop + root.anchorPoint.y - card.height / 2, screenH - card.height - 8))
            : Math.max(8, Math.min(dockLeft + root.anchorPoint.x - card.width / 2, screenW - card.width - 8))

        anchors {
            top: root.side === "top" || root.vertical
            bottom: root.side === "bottom"
            left: root.side === "left" || !root.vertical
            right: root.side === "right"
        }
        margins {
            top: root.side === "top" ? root.dockWindow.height : (root.vertical ? along : 0)
            bottom: root.side === "bottom" ? root.dockWindow.height : 0
            left: root.side === "left" ? root.dockWindow.width : (root.vertical ? 0 : along)
            right: root.side === "right" ? root.dockWindow.width : 0
        }
        implicitWidth: card.width
        implicitHeight: card.height

        Rectangle {
            id: card
            width: 240
            height: list.implicitHeight + 16
            radius: 14
            color: Pal.Palette.glass
            border.color: Pal.Palette.glassEdge
            border.width: 1

            Column {
                id: list
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }

                Repeater {
                    model: root.items
                    delegate: Item {
                        id: row
                        required property var modelData
                        width: list.width
                        height: modelData.sep ? 9 : 30

                        // Separator
                        Rectangle {
                            visible: !!row.modelData.sep
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 8; rightMargin: 8 }
                            height: 1
                            color: Pal.Palette.surfaceEdge
                        }

                        // Item row
                        Rectangle {
                            visible: !row.modelData.sep
                            anchors.fill: parent
                            radius: 8
                            color: rowMa.containsMouse ? Pal.Palette.surfaceHover : "transparent"

                            Text {
                                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 10; rightMargin: 10 }
                                text: row.modelData.label || ""
                                color: Pal.Palette.textPrimary
                                font.pixelSize: Theme.fontSmall
                                elide: Text.ElideRight
                                textFormat: Text.PlainText
                            }

                            MouseArea {
                                id: rowMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.choose(row.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
