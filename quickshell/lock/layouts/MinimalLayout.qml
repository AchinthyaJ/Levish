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
        spacing: Math.round(22 * root.screenScale)

        HeroClock {
            Layout.alignment: Qt.AlignHCenter
            themeStore: root.themeStore
            screenScale: root.screenScale * 0.95
            alignment: Qt.AlignHCenter
        }

        Item { Layout.preferredHeight: Math.round(14 * root.screenScale) }

        UserIdentity {
            Layout.alignment: Qt.AlignHCenter
            themeStore: root.themeStore
            screenScale: root.screenScale * 0.9
            alignment: Qt.AlignHCenter
        }

        Item { Layout.preferredHeight: Math.round(8 * root.screenScale) }

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
    }
}
