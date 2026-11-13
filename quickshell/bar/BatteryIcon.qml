// Phone-style battery: an outlined body with a terminal nub and a level fill.
// State colour: white normally, green while charging (with a bolt), red when low.
import QtQuick
import "../common" as C
import "../common/Theme.js" as Theme

Item {
    id: batt
    property real level: 0          // 0..100
    property bool charging: false
    readonly property bool low: !charging && level <= 20
    readonly property string stateColor: charging ? "#86efac" : (low ? "#e94560" : Theme.text)

    implicitWidth: 28
    implicitHeight: 18

    Rectangle {
        id: body
        width: 25; height: 12
        anchors.verticalCenter: parent.verticalCenter
        x: 0
        radius: 3.5
        color: "transparent"
        border.width: 1.5
        border.color: (batt.charging || batt.low) ? batt.stateColor : "#b8c6d8"
        Behavior on border.color { ColorAnimation { duration: 250 } }

        // Level fill, inset so it sits inside the outline.
        Rectangle {
            x: 2.5; y: 2.5
            height: body.height - 5
            width: (body.width - 5) * Math.max(0, Math.min(100, batt.level)) / 100
            radius: 1.5
            color: batt.stateColor
            Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 250 } }
        }

        C.Icon {
            anchors.centerIn: parent
            width: 12; height: 12
            kind: "bolt"
            tint: "#f5f9fd"
            visible: batt.charging
        }
    }

    // Terminal nub on the right edge.
    Rectangle {
        x: body.x + body.width + 1
        width: 2; height: 5; radius: 1
        anchors.verticalCenter: parent.verticalCenter
        color: body.border.color
        Behavior on color { ColorAnimation { duration: 250 } }
    }
}
