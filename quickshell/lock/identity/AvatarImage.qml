import QtQuick
import Quickshell
import "../../common" as C
import "../../common/Theme.js" as Theme

Item {
    id: root

    property var themeStore: null
    property real size: 76
    property string username: Quickshell.env("USER") || ""

    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string resolvedAvatar: {
        if (themeStore && themeStore.lockCustomAvatar && themeStore.lockCustomAvatar !== "") {
            return themeStore.lockCustomAvatar
        }
        if (homeDir !== "") {
            return homeDir + "/.face"
        }
        return ""
    }

    implicitWidth: size
    implicitHeight: size

    // Outer subtle glowing aura ring
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.color: root.themeStore ? root.themeStore.accentColor : "#c8f7ef"
        border.width: 1.5
        opacity: 0.75
    }

    // Avatar image container
    Item {
        id: imageMask
        anchors.fill: parent
        anchors.margins: 3

        Rectangle {
            id: maskRect
            anchors.fill: parent
            radius: width / 2
            color: "#16202c"
            clip: true

            Image {
                id: avatarImg
                anchors.fill: parent
                source: root.resolvedAvatar !== "" ? (root.resolvedAvatar.startsWith("/") ? "file://" + root.resolvedAvatar : root.resolvedAvatar) : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                visible: status === Image.Ready
            }

            // Fallback monogram / icon if no face picture is loaded
            Rectangle {
                anchors.fill: parent
                visible: !avatarImg.visible
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#1e2e3d" }
                    GradientStop { position: 1.0; color: "#111a24" }
                }

                Text {
                    anchors.centerIn: parent
                    text: root.username !== "" ? root.username.charAt(0).toUpperCase() : "U"
                    color: root.themeStore ? root.themeStore.accentColor : "#c8f7ef"
                    font.family: root.themeStore ? root.themeStore.fontFamily : "JetBrains Mono"
                    font.pixelSize: Math.round(root.size * 0.42)
                    font.weight: Font.Bold
                }
            }
        }
    }
}
