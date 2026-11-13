// Power button: accent power icon, brightens on hover.
import QtQuick
import "../common" as C
import "../common/Theme.js" as Theme

Rectangle {
    id: btn
    signal clicked()
    implicitWidth: 24; implicitHeight: 24
    radius: 12
    color: ma.containsMouse ? "#33e94560" : "#14ffffff"
    Behavior on color { ColorAnimation { duration: 160 } }
    C.Icon {
        anchors.centerIn: parent
        width: 13; height: 13
        kind: "power"
        tint: Theme.accent
    }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: btn.clicked() }
}
