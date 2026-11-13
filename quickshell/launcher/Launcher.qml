// Application launcher, built in Quickshell. A pure-black, minimal panel: a quiet search
// line and a grid of installed apps. Left-click launches; right-click pins or unpins
// (pinned apps show a dot and appear in the dock). Escape or a click outside closes it.
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../common/Theme.js" as Theme

PanelWindow {
    id: win
    required property var dockState     // DockModel: desktop-entry list, pinning
    property bool open: false
    signal closeRequested()

    readonly property int columns: 5

    visible: open
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "#14000000"
    WlrLayershell.namespace: "levish-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onOpenChanged: if (open) { search.text = ""; search.forceActiveFocus(); enter.restart() }

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
        width: Math.round(win.width * 0.28)     // ~28% of the screen width
        height: Math.round(win.height * 0.44)   // ~44% of the screen height
        anchors.centerIn: parent
        radius: 26
        color: "#c7000000"          // translucent black: ~78% opaque
        border.color: "#22ffffff"
        border.width: 1

        // Gentle opening: slight scale-up and fade-in.
        opacity: 0
        scale: 0.96
        function reveal() { opacity = 1; scale = 1 }
        NumberAnimation { id: enter; target: panel; properties: "opacity,scale"; from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic }
        Connections {
            target: win
            function onOpenChanged() { if (win.open) panel.reveal() }
        }

        // Swallow clicks on the panel so they do not reach the outside-click handler.
        MouseArea { anchors.fill: parent; onClicked: {} }

        Text {
            id: label
            anchors { left: parent.left; top: parent.top; leftMargin: 24; topMargin: 20 }
            text: "APPLICATIONS"
            color: "#66ffffff"
            font.pixelSize: 10
            font.letterSpacing: 2
            font.weight: Font.DemiBold
        }

        TextInput {
            id: search
            anchors { left: parent.left; right: parent.right; top: label.bottom; leftMargin: 24; rightMargin: 24; topMargin: 10 }
            height: 34
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.text
            font.pixelSize: 17
            font.weight: Font.Light
            clip: true
            selectByMouse: true
            focus: win.open

            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                visible: search.text.length === 0
                text: "Search"
                color: "#44ffffff"
                font.pixelSize: 17
                font.weight: Font.Light
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
            anchors { left: parent.left; right: parent.right; top: search.bottom; topMargin: 12; leftMargin: 24; rightMargin: 24 }
            height: 1
            color: "#1affffff"
        }

        GridView {
            id: grid
            anchors { left: parent.left; right: parent.right; top: divider.bottom; bottom: hint.top; leftMargin: 16; rightMargin: 16 }
            anchors.topMargin: 10
            anchors.bottomMargin: 8
            clip: true
            cellWidth: Math.floor(width / win.columns)
            cellHeight: 104
            model: win.results
            boundsBehavior: Flickable.StopAtBounds
            currentIndex: 0
            onCountChanged: currentIndex = 0

            delegate: Item {
                required property var modelData
                required property int index
                width: grid.cellWidth
                height: grid.cellHeight

                readonly property bool selected: index === grid.currentIndex || cell.containsMouse

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 5
                    radius: 18
                    color: selected ? "#14ffffff" : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Image {
                        id: ico
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 12
                        width: 44; height: 44
                        source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        smooth: true
                        mipmap: true
                        transformOrigin: Item.Bottom
                        scale: selected ? 1.08 : 1
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    }
                    Text {
                        anchors { left: parent.left; right: parent.right; top: ico.bottom; topMargin: 9; leftMargin: 8; rightMargin: 8 }
                        text: modelData.name
                        color: selected ? "#ffffff" : "#bfffffff"
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    // Pinned indicator
                    Rectangle {
                        visible: win.dockState.isPinned(modelData)
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 6 }
                        width: 4; height: 4; radius: 2
                        color: "#ffffff"
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
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: 14; leftMargin: 24; rightMargin: 24 }
            text: "Enter to launch  ·  Right-click to pin"
            color: "#55ffffff"
            font.pixelSize: 10
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
