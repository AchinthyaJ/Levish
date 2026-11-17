// Quick-settings tile. The left part toggles (icon, title, status line); a separate chevron
// column on the right opens the device list. A busy tile pulses its badge and shows a
// status line such as "Turning on…" until the radio actually changes.
import QtQuick
import QtQuick.Layouts
import "../common" as C
import "../common/Theme.js" as Theme
import "../common" as Pal

Rectangle {
    id: tile
    property string kind: ""
    property string title: ""
    property string subtitle: ""
    property bool checked: false
    property bool expandable: false
    property bool busy: false
    property string busyLabel: ""
    signal toggled()
    signal expandRequested()

    readonly property int chevronWidth: 44

    Layout.fillWidth: true
    implicitHeight: 66
    radius: 22
    color: checked ? Qt.rgba(Pal.Palette.accent.r, Pal.Palette.accent.g, Pal.Palette.accent.b, 0.141) : Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.071)
    border.width: 1
    border.color: checked ? Qt.rgba(Pal.Palette.accent.r, Pal.Palette.accent.g, Pal.Palette.accent.b, 0.251) : Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.078)
    Behavior on color { ColorAnimation { duration: Theme.dur(180) } }
    Behavior on border.color { ColorAnimation { duration: Theme.dur(180) } }

    // ── Toggle area: everything left of the chevron column ───────────────
    MouseArea {
        id: toggleMA
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; right: divider.left }
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.toggled()

        Rectangle {
            anchors.fill: parent
            radius: tile.radius
            color: toggleMA.containsMouse ? Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.078) : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.dur(140) } }
        }

        RowLayout {
            anchors { fill: parent; leftMargin: 10; rightMargin: 6 }
            spacing: 8

            Rectangle {
                id: badge
                Layout.preferredWidth: 32; Layout.preferredHeight: 32
                radius: 16
                color: tile.checked ? Pal.Palette.accent : Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.094)
                Behavior on color { ColorAnimation { duration: Theme.dur(180) } }
                C.Icon {
                    anchors.centerIn: parent
                    width: 15; height: 15
                    kind: tile.kind
                    tint: tile.checked ? Theme.solidPanel : Pal.Palette.text
                }
                // Pulse while the radio is switching.
                SequentialAnimation on opacity {
                    running: tile.busy
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.25; duration: Theme.dur(550); easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 1;    duration: Theme.dur(550); easing.type: Easing.InOutQuad }
                }
                onOpacityChanged: if (!tile.busy && opacity !== 1) opacity = 1
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text {
                    text: tile.title; color: Pal.Palette.text
                    font.pixelSize: Theme.fs(13); font.weight: Font.DemiBold
                    elide: Text.ElideRight; Layout.fillWidth: true
                }
                Text {
                    text: tile.busy ? tile.busyLabel : tile.subtitle
                    color: tile.busy ? Pal.Palette.accent : Pal.Palette.muted
                    font.pixelSize: Theme.fs(10)
                    elide: Text.ElideRight; Layout.fillWidth: true
                }
            }
        }
    }

    // ── Divider between the toggle and the chevron ───────────────────────
    Rectangle {
        id: divider
        visible: tile.expandable
        anchors { right: parent.right; rightMargin: tile.chevronWidth; verticalCenter: parent.verticalCenter }
        width: 1; height: 30
        color: Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.102)
    }

    // ── Chevron area: its own wide, clearly separate hit target ─────────
    Item {
        id: chevronArea
        visible: tile.expandable
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
        width: tile.chevronWidth

        Rectangle {
            anchors.centerIn: parent
            width: 28; height: 28; radius: 14
            color: chevMA.containsMouse ? Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.133) : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.dur(140) } }
            C.Icon {
                anchors.centerIn: parent
                width: 12; height: 12
                kind: "down"; tint: Pal.Palette.muted
                rotation: -90
            }
        }
        MouseArea {
            id: chevMA
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.expandRequested()
        }
    }
}
