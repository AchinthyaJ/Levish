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
        width: Math.min(parent.width * 0.88, Math.round(1020 * root.screenScale))
        spacing: Math.round(50 * root.screenScale)

        // Left Column: Time & Environmental Insight
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Math.round(20 * root.screenScale)

            HeroClock {
                Layout.alignment: Qt.AlignLeft
                themeStore: root.themeStore
                screenScale: root.screenScale
                alignment: Qt.AlignLeft
            }

            Item { Layout.preferredHeight: Math.round(10 * root.screenScale) }

            WeatherWidget {
                themeStore: root.themeStore
                screenScale: root.screenScale
                weatherData: root.weatherService ? root.weatherService.weatherData : null
                visible: !(root.themeStore && root.themeStore.lockDisableWidgets) && (root.themeStore ? root.themeStore.lockShowWeather : true)
            }

            RowLayout {
                spacing: Math.round(8 * root.screenScale)
                visible: !(root.themeStore && root.themeStore.lockDisableWidgets)

                BatteryWidget {
                    themeStore: root.themeStore
                    screenScale: root.screenScale
                    battery: (root.store && root.store.battery) ? root.store.battery : ({ percent: 100, charging: false })
                    visible: (root.themeStore ? root.themeStore.lockShowBattery : true) && (root.store && root.store.battery && root.store.battery.has_battery !== false)
                }

                NetworkWidget {
                    themeStore: root.themeStore
                    screenScale: root.screenScale
                    network: (root.store && root.store.network) ? root.store.network : ({})
                    bluetooth: (root.store && root.store.bluetooth) ? root.store.bluetooth : ({})
                    visible: root.themeStore ? root.themeStore.lockShowNetwork : true
                }
            }
        }

        // Vertical divider
        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: Math.round(320 * root.screenScale)
            color: "#20ffffff"
        }

        // Right Column: Identity, Authentication & Media
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Math.round(18 * root.screenScale)

            UserIdentity {
                Layout.alignment: Qt.AlignHCenter
                themeStore: root.themeStore
                screenScale: root.screenScale
                alignment: Qt.AlignHCenter
            }

            PasswordField {
                Layout.alignment: Qt.AlignHCenter
                pam: root.pam
                themeStore: root.themeStore
                screenScale: root.screenScale
            }

            AuthStatus {
                Layout.alignment: Qt.AlignHCenter
                pam: root.pam
                themeStore: root.themeStore
                screenScale: root.screenScale
            }

            Item { Layout.preferredHeight: Math.round(8 * root.screenScale) }

            MediaWidget {
                Layout.alignment: Qt.AlignHCenter
                themeStore: root.themeStore
                screenScale: root.screenScale
                media: (root.store && root.store.media) ? root.store.media : ({})
                visible: !(root.themeStore && root.themeStore.lockDisableWidgets) && (root.themeStore ? root.themeStore.lockShowMedia : true)
            }
        }
    }
}
