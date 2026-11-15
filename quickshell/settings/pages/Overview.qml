import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../components"

// Landing page: what is configured right now, plus shortcuts to each page.
Flickable {
    id: page
    property var themeStore
    property string pageId: ""
    property string keywords: "overview summary status health configuration"
    readonly property var resetPaths: []
    readonly property color accent: themeStore.accentColor
    signal navigate(string pageId)

    contentHeight: col.implicitHeight + 40
    clip: true

    ColumnLayout {
        id: col
        x: 24; y: 20
        width: page.width - 48
        spacing: 14

        Rectangle {
            visible: page.themeStore.status !== "ok"
            Layout.fillWidth: true
            implicitHeight: banner.implicitHeight + 20
            radius: 10
            color: "#22e94560"
            border.color: "#55e94560"
            Text {
                id: banner
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 12 }
                text: page.themeStore.statusDetail
                color: "#f5f9fd"
                font.pixelSize: 12
                wrapMode: Text.Wrap
            }
        }

        SettingsCard {
            title: "Current configuration"
            SettingsRow { label: "Accent colour"
                Text { text: page.themeStore.accentColor; color: page.accent; font.pixelSize: 12 } }
            SettingsRow { label: "Bar and dock opacity"
                Text { text: Math.round(page.themeStore.glassOpacity * 100) + "% / " + Math.round(page.themeStore.dockOpacity * 100) + "%"; color: "#c9d6e8"; font.pixelSize: 12 } }
            SettingsRow { label: "Top bar height"
                Text { text: page.themeStore.barHeight + " px"; color: "#c9d6e8"; font.pixelSize: 12 } }
            SettingsRow { label: "Dock"
                Text { text: (page.themeStore.dockEnabled ? "Shown" : "Hidden") + (page.themeStore.dockAutoHide ? ", auto-hide" : ""); color: "#c9d6e8"; font.pixelSize: 12 } }
            SettingsRow { label: "Launcher"
                Text { text: page.themeStore.launcherDefaultView + ", " + page.themeStore.launcherColumns + " columns"; color: "#c9d6e8"; font.pixelSize: 12 } }
        }

        SettingsCard {
            title: "Configuration health"
            SettingsRow { label: "Settings file"; hint: page.themeStore.configPath
                Text { text: page.themeStore.status === "ok" ? "Valid" : (page.themeStore.status === "missing" ? "Not created yet" : "Needs attention")
                    color: page.themeStore.status === "ok" ? page.accent : "#f0708a"; font.pixelSize: 12 } }
        }

        SettingsCard {
            title: "Customise"
            Flow {
                Layout.fillWidth: true
                spacing: 8
                SettingsButton { text: "Appearance"; onClicked: page.navigate("appearance") }
                SettingsButton { text: "Top bar"; onClicked: page.navigate("topbar") }
                SettingsButton { text: "Dock"; onClicked: page.navigate("dock") }
                SettingsButton { text: "Launcher"; onClicked: page.navigate("launcher") }
            }
        }
    }
}
