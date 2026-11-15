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

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Math.round(20 * root.screenScale)

        // Center Hero Clock & Date
        HeroClock {
            Layout.alignment: Qt.AlignHCenter
            themeStore: root.themeStore
            screenScale: root.screenScale
            alignment: Qt.AlignHCenter
        }

        Item { Layout.preferredHeight: Math.round(10 * root.screenScale) }

        // Center User Identity
        UserIdentity {
            Layout.alignment: Qt.AlignHCenter
            themeStore: root.themeStore
            screenScale: root.screenScale
            alignment: Qt.AlignHCenter
        }

        Item { Layout.preferredHeight: Math.round(4 * root.screenScale) }

        // Center Password Field
        PasswordField {
            id: pwdField
            Layout.alignment: Qt.AlignHCenter
            pam: root.pam
            themeStore: root.themeStore
            screenScale: root.screenScale
        }

        // Authentication Feedback Banner
        AuthStatus {
            Layout.alignment: Qt.AlignHCenter
            pam: root.pam
            themeStore: root.themeStore
            screenScale: root.screenScale
        }

        Item { Layout.preferredHeight: Math.round(12 * root.screenScale) }

        // Media playback card if active
        MediaWidget {
            Layout.alignment: Qt.AlignHCenter
            themeStore: root.themeStore
            screenScale: root.screenScale
            media: (root.store && root.store.media) ? root.store.media : ({})
            visible: !(root.themeStore && root.themeStore.lockDisableWidgets) && (root.themeStore ? root.themeStore.lockShowMedia : true)
        }

        // Bottom Environmental & System Status Bar
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Math.round(10 * root.screenScale)
            visible: !(root.themeStore && root.themeStore.lockDisableWidgets)

            WeatherWidget {
                themeStore: root.themeStore
                screenScale: root.screenScale
                weatherData: root.weatherService ? root.weatherService.weatherData : null
                visible: root.themeStore ? root.themeStore.lockShowWeather : true
            }

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

            SysStatusWidget {
                themeStore: root.themeStore
                screenScale: root.screenScale
                store: root.store
                visible: root.themeStore ? root.themeStore.lockShowUptime : false
            }
        }
    }
}
