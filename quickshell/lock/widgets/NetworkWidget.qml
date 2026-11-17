import QtQuick
import QtQuick.Layouts
import "../../common" as C
import "../../common/Theme.js" as Theme
import "../../common" as Pal

Rectangle {
    id: root

    property var network: ({ connected: false, ssid: "" })
    property var bluetooth: ({ enabled: false, devices: [] })
    property var themeStore: null
    property real screenScale: 1.0

    readonly property bool isConnected: network ? network.connected : false
    readonly property string ssid: (network && network.ssid) ? network.ssid : "Disconnected"
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

        // Wi-Fi
        RowLayout {
            spacing: Math.round(5 * root.screenScale)
            C.Icon {
                Layout.preferredWidth: Math.round(14 * root.screenScale)
                Layout.preferredHeight: Math.round(14 * root.screenScale)
                kind: root.isConnected ? "wifi" : "wifiOff"
                tint: root.isConnected ? root.accent : "#788c9f"
            }
            Text {
                text: root.ssid
                color: root.isConnected ? "#f5f9fd" : "#8aa0b4"
                font.family: root.themeStore ? root.themeStore.fontFamily : "JetBrains Mono"
                font.pixelSize: Math.round(11 * root.screenScale)
                font.weight: Font.Medium
                elide: Text.ElideRight
                Layout.maximumWidth: Math.round(100 * root.screenScale)
            }
        }

        // Bluetooth separator & indicator
        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: Math.round(12 * root.screenScale)
            color: "#30ffffff"
        }

        C.Icon {
            Layout.preferredWidth: Math.round(13 * root.screenScale)
            Layout.preferredHeight: Math.round(13 * root.screenScale)
            kind: "bluetooth"
            tint: (root.bluetooth && root.bluetooth.enabled) ? root.accent : "#5a6e80"
        }
    }
}
