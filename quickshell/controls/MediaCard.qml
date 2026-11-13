// Media playback card: album art, title/artist, prev/play/next controls.
// Standalone reusable component; ControlCenter also has this logic inline.
// Hidden when no player is active (store.media.player === "").
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../common" as C
import "../common/Theme.js" as Theme

Rectangle {
    id: card
    property var media: ({ player: "", playing: false, title: "", artist: "", art_url: "" })

    // Command pipe — caller sets this or uses _cmd() directly
    signal action(string name)

    visible: card.media.player !== ""
    radius: 20
    color: Theme.solidCard
    border.color: Theme.solidCardEdge
    border.width: 1
    implicitHeight: 80

    RowLayout {
        anchors { fill: parent; margins: 12 }
        spacing: 12

        // Album art (or note icon fallback)
        Rectangle {
            Layout.preferredWidth: 52; Layout.preferredHeight: 52
            radius: 12; color: "#1fc8f7ef"; clip: true
            Image {
                id: art; anchors.fill: parent
                source: card.media.art_url || ""
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
            }
            C.Icon {
                anchors.centerIn: parent
                width: 20; height: 20
                kind: "note"; tint: Theme.accent
                visible: !art.visible
            }
        }

        ColumnLayout {
            Layout.fillWidth: true; spacing: 2
            Text {
                text: card.media.title || ""
                color: Theme.text; font.pixelSize: 13; font.weight: Font.Medium
                elide: Text.ElideRight; Layout.fillWidth: true
            }
            Text {
                text: card.media.artist || ""
                color: Theme.muted; font.pixelSize: 10
                elide: Text.ElideRight; Layout.fillWidth: true
            }
        }

        // Transport controls
        Row {
            spacing: 2
            Repeater {
                model: [
                    { kind: "prev", act: "previous", accent: false },
                    { kind: card.media.playing ? "pause" : "play", act: "play_pause", accent: true },
                    { kind: "next", act: "next", accent: false }
                ]
                delegate: Rectangle {
                    required property var modelData
                    implicitWidth: 30; implicitHeight: 30; radius: 9
                    color: btnMA.containsMouse
                           ? (modelData.accent ? "#33c8f7ef" : "#22ffffff")
                           : "transparent"
                    Behavior on color { ColorAnimation { duration: 130 } }
                    C.Icon {
                        anchors.centerIn: parent
                        width: modelData.accent ? 16 : 13; height: modelData.accent ? 16 : 13
                        kind: modelData.kind
                        tint: modelData.accent ? Theme.accent : Theme.text
                    }
                    MouseArea {
                        id: btnMA; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.action(modelData.act)
                    }
                }
            }
        }
    }
}
