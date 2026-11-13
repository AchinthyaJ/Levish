// One application cell: real icon, restrained hover zoom, focus backdrop, running dot and
// tooltip. A click focuses an open window (cycling through several) or launches the app.
import QtQuick
import Quickshell
import "../common/Theme.js" as Theme

Item {
    id: cell

    required property var dockState       // DockModel
    required property int iconSize
    required property string label        // app name, shown in the tooltip
    required property var entry           // DesktopEntry, or null when unknown
    required property string matchClass   // window class for an unpinned running app, else ""

    readonly property var windows: dockState.windowsFor(entry, matchClass)
    readonly property bool running: windows.length > 0
    readonly property bool focusedApp: windows.some(w => dockState.isFocused(w))
    readonly property string iconSource: Quickshell.iconPath(
        entry ? entry.icon : matchClass.toLowerCase(), "application-x-executable")

    width: iconSize + Theme.dockCellPad
    height: iconSize + 14

    function activate() {
        const ws = cell.windows
        if (ws.length === 0) {
            if (cell.entry) cell.entry.execute()
            return
        }
        let target = ws[0]
        if (cell.focusedApp && ws.length > 1) {
            const i = ws.findIndex(w => dockState.isFocused(w))
            target = ws[(i + 1) % ws.length]
        }
        dockState.focusWindow(target)
    }

    // Backdrop: neutral hover tint, or a quieter tint for the focused app.
    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: 14
        color: hover.containsMouse ? Theme.dockHover : (cell.focusedApp ? Theme.dockActive : "transparent")
        Behavior on color { ColorAnimation { duration: 160 } }
    }

    Image {
        id: icon
        width: cell.iconSize
        height: cell.iconSize
        x: (cell.width - width) / 2
        y: 4
        source: cell.iconSource
        fillMode: Image.PreserveAspectFit   // never stretch non-square icons
        asynchronous: true
        smooth: true
        mipmap: true
        transformOrigin: Item.Bottom
        scale: hover.containsMouse ? Theme.dockZoom : 1
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }

    // Placeholder only when the icon genuinely cannot be loaded.
    Rectangle {
        visible: icon.status === Image.Error || icon.status === Image.Null
        x: icon.x; y: icon.y
        width: icon.width; height: icon.height
        radius: 12
        color: "#18ffffff"
        border.color: Theme.dockEdge
        border.width: 1
        Text {
            anchors.centerIn: parent
            text: cell.label.length > 0 ? cell.label.charAt(0).toUpperCase() : "?"
            color: Theme.muted
            font.pixelSize: cell.iconSize * 0.42
            font.weight: Font.Bold
        }
    }

    // Running indicator: a dot, stretched into a short bar when the app has focus.
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: cell.height - 5
        height: 4
        radius: 2
        width: cell.focusedApp ? 12 : 4
        color: Theme.dockDot
        opacity: cell.running ? 1 : 0
        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 160 } }
    }

    // Tooltip sits in the headroom above the glass.
    Rectangle {
        id: tip
        anchors.horizontalCenter: parent.horizontalCenter
        y: -height - 8
        width: tipText.implicitWidth + 16
        height: 24
        radius: 8
        color: Theme.dockTipBg
        border.color: Theme.dockEdge
        border.width: 1
        opacity: hover.containsMouse && cell.label.length > 0 ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 140 } }
        Text {
            id: tipText
            anchors.centerIn: parent
            text: cell.label
            color: Theme.text
            font.pixelSize: 12
            font.weight: Font.Medium
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                if (cell.entry) cell.dockState.togglePin(cell.entry)
            } else {
                cell.activate()
            }
        }
    }
}
