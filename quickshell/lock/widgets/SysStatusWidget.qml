import QtQuick
import QtQuick.Layouts
import "../../common" as C
import "../../common/Theme.js" as Theme
import "../../common" as Pal

Rectangle {
    id: root

    property var store: null
    property var themeStore: null
    property real screenScale: 1.0

    readonly property string uptimeStr: (store && store.uptime) ? store.uptime : ""
    readonly property var audioData: (store && store.audio) ? store.audio : ({ volume: 50, muted: false })
    readonly property color accent: themeStore ? themeStore.accentColor : Pal.Palette.accent

    implicitHeight: Math.round(32 * screenScale)
    implicitWidth: row.implicitWidth + Math.round(20 * screenScale)
    radius: height / 2

    color: "#121b25aa"
    border.color: "#25ffffff"
    border.width: 1

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(8 * root.screenScale)

        // Audio volume
        RowLayout {
            spacing: Math.round(5 * root.screenScale)

            C.Icon {
                Layout.preferredWidth: Math.round(14 * root.screenScale)
                Layout.preferredHeight: Math.round(14 * root.screenScale)
                kind: root.audioData.muted ? "mute" : "volume"
                tint: root.audioData.muted ? "#f0708a" : root.accent
            }

            Text {
                text: root.audioData.muted ? "Muted" : Math.round(root.audioData.volume) + "%"
                color: "#f5f9fd"
                font.family: root.themeStore ? root.themeStore.fontFamily : "JetBrains Mono"
                font.pixelSize: Math.round(11 * root.screenScale)
                font.weight: Font.Medium
            }
        }

        // Uptime separator & label
        Rectangle {
            visible: (root.themeStore ? root.themeStore.lockShowUptime : false) && root.uptimeStr !== ""
            Layout.preferredWidth: 1
            Layout.preferredHeight: Math.round(12 * root.screenScale)
            color: "#30ffffff"
        }

        RowLayout {
            visible: (root.themeStore ? root.themeStore.lockShowUptime : false) && root.uptimeStr !== ""
            spacing: Math.round(4 * root.screenScale)

            Text {
                text: "Up " + root.uptimeStr
                color: "#8ca2b8"
                font.family: root.themeStore ? root.themeStore.fontFamily : "JetBrains Mono"
                font.pixelSize: Math.round(11 * root.screenScale)
            }
        }
    }
}
