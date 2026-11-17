// One application cell: real icon, restrained hover zoom, focus backdrop, running dots and
// tooltip. A click focuses an open window (cycling through several) or launches the app.
// `side` is the screen edge the dock sits on. Dots sit on the outer side, and tooltips open on the
// inner side, so they never fall off the screen.
import QtQuick
import Quickshell
import "../common/Theme.js" as Theme
import "../common" as Pal

Item {
    id: cell

    required property var dockState       // DockModel
    required property int iconSize
    required property string label        // app name, shown in the tooltip
    required property var entry           // DesktopEntry, or null when unknown
    required property string matchClass   // window class for an unpinned running app, else ""
    property real zoom: Theme.dockZoom     // hover enlargement, from dock.zoom
    property string side: "bottom"         // screen edge the dock is on

    readonly property bool vertical: side === "left" || side === "right"
    readonly property var windows: dockState.windowsFor(entry, matchClass)
    readonly property bool running: windows.length > 0
    readonly property bool focusedApp: windows.some(w => dockState.isFocused(w))
    readonly property string iconSource: Quickshell.iconPath(
        entry ? entry.icon : matchClass.toLowerCase(), "application-x-executable")

    // Along the dock the cell is the icon plus padding; across it, the icon plus the dot room.
    width: vertical ? iconSize + 14 : iconSize + Theme.dockCellPad
    height: vertical ? iconSize + Theme.dockCellPad : iconSize + 14

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
        color: hover.containsMouse ? Pal.Palette.dockHover : (cell.focusedApp ? Pal.Palette.dockActive : "transparent")
        Behavior on color { ColorAnimation { duration: Theme.dur(160) } }
    }

    Image {
        id: icon
        width: cell.iconSize
        height: cell.iconSize
        // Icon sits against the inner edge of the cell on side docks, at the top on horizontal ones.
        x: cell.vertical ? 4 : (cell.width - width) / 2
        y: cell.vertical ? (cell.height - height) / 2 : 4
        source: cell.iconSource
        fillMode: Image.PreserveAspectFit   // never stretch non-square icons
        asynchronous: true
        smooth: true
        mipmap: true
        transformOrigin: Item.Center
        scale: hover.containsMouse ? cell.zoom : 1
        Behavior on scale { NumberAnimation { duration: Theme.dur(180); easing.type: Easing.OutCubic } }
    }

    // Placeholder only when the icon genuinely cannot be loaded.
    Rectangle {
        visible: icon.status === Image.Error || icon.status === Image.Null
        x: icon.x; y: icon.y
        width: icon.width; height: icon.height
        radius: 12
        color: Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.094)
        border.color: Pal.Palette.dockEdge
        border.width: 1
        Text {
            anchors.centerIn: parent
            text: cell.label.length > 0 ? cell.label.charAt(0).toUpperCase() : "?"
            color: Pal.Palette.muted
            font.pixelSize: Theme.fs(cell.iconSize * 0.42)
            font.weight: Font.Bold
        }
    }

    // Running indicators: one dot per open window of this app. The focused window's dot is
    // stretched into a short bar. The row sits on the outer edge of the cell.
    Grid {
        x: cell.vertical ? (cell.side === "left" ? 1 : cell.width - 5) : (cell.width - width) / 2
        y: cell.vertical ? (cell.height - height) / 2 : (cell.side === "top" ? 1 : cell.height - 5)
        spacing: 3
        flow: cell.vertical ? Grid.TopToBottom : Grid.LeftToRight
        columns: cell.vertical ? 1 : 1000
        opacity: cell.running ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.dur(160) } }

        Repeater {
            model: cell.windows.length
            Rectangle {
                required property int index
                readonly property bool active: index < cell.windows.length
                    && cell.dockState.isFocused(cell.windows[index])
                height: cell.vertical ? (active ? 12 : 4) : 4
                width: cell.vertical ? 4 : (active ? 12 : 4)
                radius: 2
                color: Pal.Palette.dockDot
                Behavior on width { NumberAnimation { duration: Theme.dur(180); easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: Theme.dur(180); easing.type: Easing.OutCubic } }
            }
        }
    }

    // Tooltip sits on the inner side of the dock, in the headroom beside the glass.
    Rectangle {
        id: tip
        readonly property bool above: cell.side === "bottom"
        readonly property bool below: cell.side === "top"
        readonly property bool toRight: cell.side === "left"
        readonly property bool toLeft: cell.side === "right"
        x: toRight ? cell.width + 8 : (toLeft ? -width - 8 : (cell.width - width) / 2)
        y: above ? -height - 8 : (below ? cell.height + 8 : (cell.height - height) / 2)
        width: tipText.implicitWidth + 16
        height: 24
        radius: 8
        color: Pal.Palette.dockTip
        border.color: Pal.Palette.dockEdge
        border.width: 1
        opacity: hover.containsMouse && cell.label.length > 0 ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Theme.dur(140) } }
        Text {
            id: tipText
            anchors.centerIn: parent
            text: cell.label
            color: Pal.Palette.text
            font.pixelSize: Theme.fs(12)
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
