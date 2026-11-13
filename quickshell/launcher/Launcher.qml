// Application launcher, built in Quickshell. A small centred panel with a search field and
// a grid of installed apps. Left-click launches; right-click pins or unpins (pinned apps show
// a dot and appear in the dock). Escape or a click outside closes it.
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../common/Theme.js" as Theme

PanelWindow {
    id: win
    required property var dockState     // DockModel: desktop-entry list, pinning
    property bool open: false
    signal closeRequested()

    readonly property int columns: 4

    visible: open
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "#33000000"
    WlrLayershell.namespace: "levish-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onOpenChanged: if (open) { search.text = ""; search.forceActiveFocus() }

    // Visible apps, sorted by name and filtered by the query.
    readonly property var results: {
        dockState.appsRevision
        const q = search.text.trim().toLowerCase()
        const out = []
        for (const a of dockState.listOf(DesktopEntries.applications)) {
            if (a.noDisplay) continue
            if (q.length > 0) {
                const hay = (a.name + " " + (a.genericName || "") + " " + (a.keywords || "")).toLowerCase()
                if (hay.indexOf(q) < 0) continue
            }
            out.push(a)
        }
        out.sort((x, y) => x.name.localeCompare(y.name))
        return out.slice(0, 300)
    }

    function launch(entry) {
        if (!entry) return
        entry.execute()
        win.closeRequested()
    }

    // Clicking outside the panel closes the launcher.
    MouseArea { anchors.fill: parent; onClicked: win.closeRequested() }

    Rectangle {
        id: panel
        width: Math.round(win.width * 0.24)     // ~24% of the screen width
        height: Math.round(win.height * 0.36)   // ~36% of the screen height
        anchors.centerIn: parent
        radius: Theme.radiusCard
        color: Theme.glass
        border.color: Theme.glassEdge
        border.width: 1

        // Swallow clicks on the panel so they do not reach the outside-click handler.
        MouseArea { anchors.fill: parent; onClicked: {} }

        TextInput {
            id: search
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            height: 36
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.text
            font.pixelSize: 15
            clip: true
            selectByMouse: true
            focus: win.open

            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                visible: search.text.length === 0
                text: "Search applications"
                color: Theme.muted
                font.pixelSize: 15
            }

            Keys.onEscapePressed: win.closeRequested()
            Keys.onReturnPressed: win.launch(win.results[grid.currentIndex])
            Keys.onEnterPressed: win.launch(win.results[grid.currentIndex])
            Keys.onDownPressed: grid.moveCurrentIndexDown()
            Keys.onUpPressed: grid.moveCurrentIndexUp()
            Keys.onRightPressed: grid.moveCurrentIndexRight()
            Keys.onLeftPressed: grid.moveCurrentIndexLeft()
        }

        Rectangle {
            id: divider
            anchors { left: parent.left; right: parent.right; top: search.bottom; topMargin: 8; leftMargin: 12; rightMargin: 12 }
            height: 1
            color: Theme.cardStroke
        }

        GridView {
            id: grid
            anchors { left: parent.left; right: parent.right; top: divider.bottom; bottom: hint.top; margins: 8 }
            anchors.topMargin: 8
            clip: true
            cellWidth: Math.floor(width / win.columns)
            cellHeight: 92
            model: win.results
            boundsBehavior: Flickable.StopAtBounds
            currentIndex: 0
            onCountChanged: currentIndex = 0

            delegate: Item {
                required property var modelData
                required property int index
                width: grid.cellWidth
                height: grid.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: 12
                    color: (index === grid.currentIndex || cell.containsMouse) ? Theme.dockHover : "transparent"

                    Image {
                        id: ico
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 10
                        width: 40; height: 40
                        source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                    }
                    Text {
                        anchors { left: parent.left; right: parent.right; top: ico.bottom; topMargin: 8; leftMargin: 6; rightMargin: 6 }
                        text: modelData.name
                        color: Theme.text
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                    // Pinned indicator
                    Rectangle {
                        visible: win.dockState.isPinned(modelData)
                        anchors { right: parent.right; top: parent.top; rightMargin: 8; topMargin: 8 }
                        width: 6; height: 6; radius: 3
                        color: Theme.dockDot
                    }
                }

                MouseArea {
                    id: cell
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onEntered: grid.currentIndex = index
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) win.dockState.togglePin(modelData)
                        else win.launch(modelData)
                    }
                }
            }
        }

        Text {
            id: hint
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: 10; leftMargin: 12; rightMargin: 12 }
            text: "Click to launch · Right-click to pin to the dock"
            color: Theme.muted
            font.pixelSize: 11
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
