// Power button: accent power icon, brightens on hover.
import QtQuick
import "../common" as C
import "../common/Theme.js" as Theme
import "../common" as Pal

Rectangle {
    id: btn
    signal clicked()
    implicitWidth: 24; implicitHeight: 24
    radius: 12
    color: ma.containsMouse ? "#33e94560" : Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.078)
    Behavior on color { ColorAnimation { duration: Theme.dur(160) } }
    C.Icon {
        anchors.centerIn: parent
        width: 13; height: 13
        kind: "power"
        tint: Pal.Palette.accent
    }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: btn.clicked() }
}
