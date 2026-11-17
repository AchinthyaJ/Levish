import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../common" as C
import "../../common/Theme.js" as Theme
import "../../common" as Pal

Rectangle {
    id: root

    property var media: ({ player: "", playing: false, title: "", artist: "", art_url: "" })
    property var themeStore: null
    property real screenScale: 1.0

    readonly property bool hasMedia: media && media.player && media.player !== ""
    readonly property bool hideSensitive: themeStore ? themeStore.lockHideSensitiveMedia : false
    readonly property color accent: themeStore ? themeStore.accentColor : Pal.Palette.accent

    visible: hasMedia && !(themeStore && themeStore.lockDisableWidgets)

    implicitHeight: Math.round(58 * screenScale)
    implicitWidth: Math.round(320 * screenScale)
    radius: Math.round(18 * screenScale)

    color: "#141f2caa"
    border.color: Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.157)
    border.width: 1

    Process {
        id: mediaActionProc
    }

    function sendMediaAction(act) {
        if (act === "play_pause") {
            mediaActionProc.command = ["playerctl", "play-pause"]
        } else if (act === "next") {
            mediaActionProc.command = ["playerctl", "next"]
        } else if (act === "previous") {
            mediaActionProc.command = ["playerctl", "previous"]
        }
        mediaActionProc.running = true
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Math.round(8 * root.screenScale)
        spacing: Math.round(10 * root.screenScale)

        // Album art thumbnail
        Rectangle {
            Layout.preferredWidth: Math.round(42 * root.screenScale)
            Layout.preferredHeight: Math.round(42 * root.screenScale)
            radius: Math.round(10 * root.screenScale)
            color: "#1c2c3b"
            clip: true

            Image {
                id: artImg
                anchors.fill: parent
                source: (!root.hideSensitive && root.media && root.media.art_url) ? root.media.art_url : ""
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
            }

            C.Icon {
                anchors.centerIn: parent
                width: Math.round(18 * root.screenScale)
                height: Math.round(18 * root.screenScale)
                kind: "note"
                tint: root.accent
                visible: !artImg.visible
            }
        }

        // Track title & Artist
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: root.hideSensitive ? "Audio Playback" : ((root.media && root.media.title) ? root.media.title : "No title")
                color: "#f5f9fd"
                font.family: root.themeStore ? root.themeStore.fontFamily : "JetBrains Mono"
                font.pixelSize: Math.round(12 * root.screenScale)
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root.hideSensitive ? "Now Playing" : ((root.media && root.media.artist) ? root.media.artist : "Unknown artist")
                color: "#9fb0c6"
                font.family: root.themeStore ? root.themeStore.fontFamily : "JetBrains Mono"
                font.pixelSize: Math.round(10 * root.screenScale)
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        // Playback buttons
        RowLayout {
            spacing: Math.round(4 * root.screenScale)

            // Previous
            Rectangle {
                Layout.preferredWidth: Math.round(26 * root.screenScale)
                Layout.preferredHeight: Math.round(26 * root.screenScale)
                radius: width / 2
                color: prevMA.containsMouse ? Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.145) : "transparent"

                C.Icon {
                    anchors.centerIn: parent
                    width: Math.round(12 * root.screenScale)
                    height: Math.round(12 * root.screenScale)
                    kind: "prev"
                    tint: "#e2ecf7"
                }

                MouseArea {
                    id: prevMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.sendMediaAction("previous")
                }
            }

            // Play / Pause
            Rectangle {
                Layout.preferredWidth: Math.round(30 * root.screenScale)
                Layout.preferredHeight: Math.round(30 * root.screenScale)
                radius: width / 2
                color: playMA.containsMouse ? Qt.lighter(root.accent, 1.1) : root.accent

                C.Icon {
                    anchors.centerIn: parent
                    width: Math.round(13 * root.screenScale)
                    height: Math.round(13 * root.screenScale)
                    kind: (root.media && root.media.playing) ? "pause" : "play"
                    tint: "#0e141a"
                }

                MouseArea {
                    id: playMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.sendMediaAction("play_pause")
                }
            }

            // Next
            Rectangle {
                Layout.preferredWidth: Math.round(26 * root.screenScale)
                Layout.preferredHeight: Math.round(26 * root.screenScale)
                radius: width / 2
                color: nextMA.containsMouse ? Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.145) : "transparent"

                C.Icon {
                    anchors.centerIn: parent
                    width: Math.round(12 * root.screenScale)
                    height: Math.round(12 * root.screenScale)
                    kind: "next"
                    tint: "#e2ecf7"
                }

                MouseArea {
                    id: nextMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.sendMediaAction("next")
                }
            }
        }
    }
}
