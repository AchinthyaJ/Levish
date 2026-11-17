// Media playback card: album art, title/artist, prev/play/next controls.
// Standalone reusable component; ControlCenter also has this logic inline.
// Hidden when no player is active (store.media.player === "").
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../common" as C
import "../common/Theme.js" as Theme
import "../common" as Pal

Rectangle {
    id: card
    property var media: ({ player: "", playing: false, title: "", artist: "", art_url: "" })

    // Command pipe — caller sets this or uses _cmd() directly
    signal action(string name)

    visible: card.media.player !== ""
    radius: 20
    color: Pal.Palette.card
    border.color: Pal.Palette.cardEdge
    border.width: 1
    implicitHeight: 80

    RowLayout {
        anchors { fill: parent; margins: 12 }
        spacing: 12

        // Album art (or note icon fallback)
        Rectangle {
            Layout.preferredWidth: 52; Layout.preferredHeight: 52
            radius: 12; color: Qt.rgba(Pal.Palette.accent.r, Pal.Palette.accent.g, Pal.Palette.accent.b, 0.122); clip: true
            Image {
                id: art; anchors.fill: parent
                source: card.media.art_url || ""
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
            }
            C.Icon {
                anchors.centerIn: parent
                width: 20; height: 20
                kind: "note"; tint: Pal.Palette.accent
                visible: !art.visible
            }
        }

        ColumnLayout {
            Layout.fillWidth: true; spacing: 2
            Text {
                text: card.media.title || ""
                color: Pal.Palette.text; font.pixelSize: Theme.fs(13); font.weight: Font.Medium
                elide: Text.ElideRight; Layout.fillWidth: true
            }
            Text {
                text: card.media.artist || ""
                color: Pal.Palette.muted; font.pixelSize: Theme.fs(10)
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
                           ? (modelData.accent ? Qt.rgba(Pal.Palette.accent.r, Pal.Palette.accent.g, Pal.Palette.accent.b, 0.2) : Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.133))
                           : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.dur(130) } }
                    C.Icon {
                        anchors.centerIn: parent
                        width: modelData.accent ? 16 : 13; height: modelData.accent ? 16 : 13
                        kind: modelData.kind
                        tint: modelData.accent ? Pal.Palette.accent : Pal.Palette.text
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
