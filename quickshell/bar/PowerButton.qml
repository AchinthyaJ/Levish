// Power button: accent power icon, brightens on hover.
import QtQuick
import "../common" as C
import "../common/Theme.js" as Theme

Rectangle {
    id: btn
    signal clicked()
    implicitWidth: 30; implicitHeight: 30
    radius: 15
    color: ma.containsMouse ? "#33e94560" : "#14ffffff"
    Behavior on color { ColorAnimation { duration: 160 } }
    C.Icon {
        anchors.centerIn: parent
        width: 16; height: 16
        kind: "power"
        tint: Theme.accent
    }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: btn.clicked() }
}
