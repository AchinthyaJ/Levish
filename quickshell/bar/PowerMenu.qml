import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../common" as C
import "../common/Theme.js" as Theme

PanelWindow {
    id: powerWin
    property bool open: false
    property real anchorRight: 12
    property real anchorWidth: 32
    signal closeRequested()
    signal actionTriggered(string act)

    anchors { top: true; right: true }
    margins {
        top: 6
        right: Math.max(8, anchorRight - (implicitWidth - anchorWidth) / 2)
    }
    implicitWidth: 200
    implicitHeight: col.implicitHeight + 20
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.namespace: "levish-power-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    visible: open || body.opacity > 0.01

    property int selectedIndex: -1

    readonly property var items: [
        { key: "1", label: "Lock",    icon: "lock",    act: "lock",     hot: false },
        { key: "2", label: "Suspend", icon: "moon",    act: "suspend",  hot: false },
        { key: "3", label: "Restart", icon: "restart", act: "restart",  hot: false },
        { key: "4", label: "Shutdown",icon: "power",   act: "shutdown", hot: true  },
        { key: "5", label: "Logout",  icon: "logout",  act: "logout",   hot: false }
    ]

    function triggerIndex(idx) {
        if (idx >= 0 && idx < items.length) {
            const act = items[idx].act
            powerWin.actionTriggered(act)
            powerWin.closeRequested()
        }
    }

    onOpenChanged: {
        if (open) {
            selectedIndex = -1
            focusItem.forceActiveFocus()
        }
    }

    // Dismiss on click outside
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: powerWin.closeRequested()
    }

    Item {
        id: focusItem
        anchors.fill: parent
        focus: powerWin.open

        Keys.onEscapePressed: powerWin.closeRequested()
        Keys.onDigit1Pressed: powerWin.triggerIndex(0)
        Keys.onDigit2Pressed: powerWin.triggerIndex(1)
        Keys.onDigit3Pressed: powerWin.triggerIndex(2)
        Keys.onDigit4Pressed: powerWin.triggerIndex(3)
        Keys.onDigit5Pressed: powerWin.triggerIndex(4)

        Keys.onDownPressed: {
            if (powerWin.selectedIndex < powerWin.items.length - 1)
                powerWin.selectedIndex++
            else
                powerWin.selectedIndex = 0
        }
        Keys.onUpPressed: {
            if (powerWin.selectedIndex > 0)
                powerWin.selectedIndex--
            else
                powerWin.selectedIndex = powerWin.items.length - 1
        }
        Keys.onReturnPressed: if (powerWin.selectedIndex >= 0) powerWin.triggerIndex(powerWin.selectedIndex)
        Keys.onEnterPressed:  if (powerWin.selectedIndex >= 0) powerWin.triggerIndex(powerWin.selectedIndex)
    }

    Rectangle {
        id: body
        anchors.fill: parent
        radius: 16
        color: Theme.glass
        border.color: Theme.glassEdge
        border.width: 1
        opacity: powerWin.open ? 1 : 0
        scale: powerWin.open ? 1 : 0.95
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            Repeater {
                model: powerWin.items
                delegate: Rectangle {
                    id: rowItem
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: 10
                    readonly property bool isSelected: powerWin.selectedIndex === index || rowMA.containsMouse
                    color: isSelected ? (modelData.hot ? "#33e94560" : "#22ffffff") : "transparent"
                    border.color: isSelected ? (modelData.hot ? "#66e94560" : "#33ffffff") : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        // Keyboard shortcut badge
                        Rectangle {
                            implicitWidth: 18; implicitHeight: 18
                            radius: 4
                            color: "#18ffffff"
                            border.color: "#22ffffff"
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: modelData.key
                                color: Theme.muted
                                font.pixelSize: 10
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                            }
                        }

                        // Icon
                        C.Icon {
                            width: 16; height: 16
                            kind: modelData.icon
                            tint: modelData.hot ? "#f0708a" : (rowItem.isSelected ? Theme.accent : Theme.text)
                        }

                        // Label
                        Text {
                            Layout.fillWidth: true
                            text: modelData.label
                            color: rowItem.isSelected ? Theme.text : Theme.muted
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }
                    }

                    MouseArea {
                        id: rowMA
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: powerWin.selectedIndex = index
                        onClicked: powerWin.triggerIndex(index)
                    }
                }
            }
        }
    }
}
