import QtQuick
import QtQuick.Layouts
import "../clock"
import "../identity"
import "../auth"
import "../widgets"
import "../../common/Theme.js" as Theme

Item {
    id: root

    required property var themeStore
    required property var store
    required property var pam
    required property var weatherService
    property var screen: null
    property real screenScale: 1.0

    anchors.fill: parent

    RowLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.88, Math.round(1100 * root.screenScale))
        spacing: Math.round(60 * root.screenScale)

        // Left Hero & Authentication Column
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Math.round(20 * root.screenScale)

            HeroClock {
                Layout.alignment: Qt.AlignLeft
                themeStore: root.themeStore
                screenScale: root.screenScale * 1.05
                alignment: Qt.AlignLeft
            }

            Item { Layout.preferredHeight: Math.round(8 * root.screenScale) }

            UserIdentity {
                Layout.alignment: Qt.AlignLeft
                themeStore: root.themeStore
                screenScale: root.screenScale
                alignment: Qt.AlignLeft
            }

            Item { Layout.preferredHeight: Math.round(10 * root.screenScale) }

            PasswordField {
                Layout.alignment: Qt.AlignLeft
                pam: root.pam
                themeStore: root.themeStore
                screenScale: root.screenScale
            }

            AuthStatus {
                Layout.alignment: Qt.AlignLeft
                pam: root.pam
                themeStore: root.themeStore
                screenScale: root.screenScale
            }
        }

        // Right Contextual & Ambient Information Column
        ColumnLayout {
            Layout.preferredWidth: Math.round(360 * root.screenScale)
            Layout.alignment: Qt.AlignVCenter
            spacing: Math.round(18 * root.screenScale)
            visible: !(root.themeStore && root.themeStore.lockDisableWidgets)

            // Weather Widget
            WeatherWidget {
                Layout.fillWidth: true
                themeStore: root.themeStore
                screenScale: root.screenScale
                weatherData: root.weatherService ? root.weatherService.weatherData : null
                visible: root.themeStore ? root.themeStore.lockShowWeather : true
            }

            // Media Player Card
            MediaWidget {
                Layout.fillWidth: true
                themeStore: root.themeStore
                screenScale: root.screenScale
                media: (root.store && root.store.media) ? root.store.media : ({})
                visible: root.themeStore ? root.themeStore.lockShowMedia : true
            }

            // Status Bar Row (Battery + Network + Uptime)
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(8 * root.screenScale)

                BatteryWidget {
                    themeStore: root.themeStore
                    screenScale: root.screenScale
                    battery: (root.store && root.store.battery) ? root.store.battery : ({ percent: 100, charging: false })
                    visible: (root.themeStore ? root.themeStore.lockShowBattery : true) && (root.store && root.store.battery && root.store.battery.has_battery !== false)
                }

                NetworkWidget {
                    Layout.fillWidth: true
                    themeStore: root.themeStore
                    screenScale: root.screenScale
                    network: (root.store && root.store.network) ? root.store.network : ({})
                    bluetooth: (root.store && root.store.bluetooth) ? root.store.bluetooth : ({})
                    visible: root.themeStore ? root.themeStore.lockShowNetwork : true
                }
            }

            SysStatusWidget {
                Layout.alignment: Qt.AlignLeft
                themeStore: root.themeStore
                screenScale: root.screenScale
                store: root.store
                visible: root.themeStore ? root.themeStore.lockShowUptime : false
            }
        }
    }
}
