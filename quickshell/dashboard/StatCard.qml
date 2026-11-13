// Top card: icon (or a text label), title and model, a "Usage" badge, and a
// temperature line with a thin bar. Only the usage arc and its value carry the accent.
import QtQuick
import QtQuick.Layouts
import "../common" as C
import "../common/Theme.js" as Theme

Card {
    id: card
    property string kind: ""      // Icon kind shown in the ring, when set
    property string label: ""     // otherwise this text is shown in the ring
    property string title: ""
    property string subtitle: ""
    property color tint: Theme.cpu
    property real value: 0
    property var temp: null
    implicitHeight: 118

    ColumnLayout {
        anchors.fill: parent
        spacing: 6
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Item {
                Layout.preferredWidth: 40; Layout.preferredHeight: 40
                C.Ring {
                    anchors.fill: parent
                    value: card.value; arcColor: card.tint; thickness: 3
                }
                C.Icon {
                    anchors.centerIn: parent
                    visible: card.kind !== ""
                    width: 16; height: 16
                    kind: card.kind; tint: card.tint
                }
                Text {
                    anchors.centerIn: parent
                    visible: card.kind === ""
                    text: card.label; color: card.tint
                    font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 0.6
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text { text: card.title; color: Theme.text; font.pixelSize: 15; font.weight: Font.DemiBold }
                Text { text: card.subtitle; color: Theme.muted; font.pixelSize: 10; elide: Text.ElideRight; Layout.fillWidth: true }
            }
            ColumnLayout {
                spacing: 1
                Text { text: "Usage"; color: Theme.muted; font.pixelSize: 9; Layout.alignment: Qt.AlignRight }
                Rectangle {
                    Layout.alignment: Qt.AlignRight
                    implicitWidth: badgeText.implicitWidth + 20
                    implicitHeight: 26
                    radius: Theme.radiusBadge
                    color: Theme.badge
                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        text: Math.round(card.value) + "%"
                        color: card.tint
                        font.family: "JetBrains Mono"; font.pixelSize: 14; font.weight: Font.Bold
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                text: (card.temp === null ? "--" : Math.round(card.temp) + "°C")
                color: Theme.muted; font.pixelSize: 10; font.family: "JetBrains Mono"
            }
            // Thin usage track: 3px, neutral, the fill carries the accent.
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 3
                radius: 2
                color: Theme.track
                Rectangle {
                    width: parent.width * Math.min(1, card.value / 100)
                    height: parent.height; radius: 2
                    color: card.tint
                    Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                }
            }
        }
    }
}
