import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../common" as C
import "../../common/Theme.js" as Theme

ColumnLayout {
    id: root

    property var themeStore: null
    property real screenScale: 1.0
    property int alignment: Qt.AlignHCenter

    readonly property string username: Quickshell.env("USER") || "user"
    property string displayName: ""
    property string hostName: ""

    // Read display name and hostname once on startup
    Process {
        id: sysInfoProc
        command: ["sh", "-c", "getent passwd $USER | cut -d: -f5 | cut -d, -f1; hostname"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n")
                if (lines.length > 0 && lines[0].trim() !== "") {
                    root.displayName = lines[0].trim()
                }
                if (lines.length > 1 && lines[1].trim() !== "") {
                    root.hostName = lines[1].trim()
                }
            }
        }
    }

    readonly property string finalDisplayName: {
        if (root.displayName !== "") return root.displayName
        return root.username.charAt(0).toUpperCase() + root.username.slice(1)
    }

    readonly property string greeting: {
        if (root.themeStore && root.themeStore.lockCustomGreeting && root.themeStore.lockCustomGreeting !== "") {
            return root.themeStore.lockCustomGreeting
        }
        const h = new Date().getHours()
        if (h >= 5 && h < 12) return "Good morning"
        if (h >= 12 && h < 17) return "Good afternoon"
        if (h >= 17 && h < 22) return "Good evening"
        return "Welcome back"
    }

    spacing: Math.round(12 * screenScale)

    // User Avatar
    AvatarImage {
        Layout.alignment: root.alignment
        themeStore: root.themeStore
        size: Math.round(76 * root.screenScale)
        username: root.username
    }

    // Greeting & User info
    ColumnLayout {
        Layout.alignment: root.alignment
        spacing: Math.round(4 * root.screenScale)

        // Dynamic greeting
        Text {
            id: greetingLabel
            visible: (root.themeStore ? root.themeStore.lockShowGreeting : true) && !(root.themeStore && root.themeStore.lockHideUserDetails)
            Layout.alignment: root.alignment
            text: root.greeting + ","
            color: root.themeStore ? root.themeStore.accentColor : "#c8f7ef"
            font.family: root.themeStore ? root.themeStore.fontFamily : "JetBrains Mono"
            font.pixelSize: Math.round(14 * root.screenScale)
            font.weight: Font.DemiBold
        }

        // Display Name / Username
        Text {
            id: nameLabel
            visible: !(root.themeStore && root.themeStore.lockHideUserDetails)
            Layout.alignment: root.alignment
            text: (root.themeStore && root.themeStore.lockShowDisplayName) ? root.finalDisplayName : root.username
            color: "#f5f9fd"
            font.family: root.themeStore ? root.themeStore.fontFamily : "JetBrains Mono"
            font.pixelSize: Math.round(20 * root.screenScale)
            font.weight: Font.Bold
            font.letterSpacing: -0.2
        }

        // Username & Hostname tag
        RowLayout {
            Layout.alignment: root.alignment
            spacing: 6
            visible: (root.themeStore ? (root.themeStore.lockShowUsername || root.themeStore.lockShowHostname) : true)
                     && !(root.themeStore && root.themeStore.lockHideUserDetails)

            Text {
                visible: root.themeStore ? root.themeStore.lockShowUsername : true
                text: "@" + root.username
                color: "#9fb0c6"
                font.family: root.themeStore ? root.themeStore.fontFamily : "JetBrains Mono"
                font.pixelSize: Math.round(12 * root.screenScale)
            }

            Text {
                visible: (root.themeStore ? root.themeStore.lockShowHostname : false) && root.hostName !== ""
                text: "on " + root.hostName
                color: "#6b829e"
                font.family: root.themeStore ? root.themeStore.fontFamily : "JetBrains Mono"
                font.pixelSize: Math.round(12 * root.screenScale)
            }
        }
    }
}
