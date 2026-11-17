import QtQuick
import QtQuick.Layouts
import "../../common" as C
import "../../common/Theme.js" as Theme
import "../../common" as Pal

Item {
    id: root

    required property var pam
    property var themeStore: null
    property real screenScale: 1.0

    readonly property string status: root.pam ? root.pam.status : "idle"
    readonly property bool hasMessage: status !== "idle"

    implicitHeight: Math.round(28 * screenScale)
    implicitWidth: pill.implicitWidth
    visible: opacity > 0
    opacity: hasMessage ? 1 : 0

    Behavior on opacity { NumberAnimation { duration: Theme.dur(200) } }

    Rectangle {
        id: pill
        anchors.centerIn: parent
        implicitHeight: root.implicitHeight
        implicitWidth: statusRow.implicitWidth + Math.round(20 * root.screenScale)
        radius: height / 2

        readonly property color accent: root.themeStore ? root.themeStore.accentColor : Pal.Palette.accent

        color: {
            if (root.status === "error") return "#33f0708a"
            if (root.status === "success") return "#3334d399"
            return "#20141f2c"
        }

        border.color: {
            if (root.status === "error") return "#88f0708a"
            if (root.status === "success") return "#8834d399"
            return Qt.rgba(accent.r, accent.g, accent.b, 0.4)
        }
        border.width: 1

        RowLayout {
            id: statusRow
            anchors.centerIn: parent
            spacing: Math.round(6 * root.screenScale)

            C.Icon {
                Layout.preferredWidth: Math.round(12 * root.screenScale)
                Layout.preferredHeight: Math.round(12 * root.screenScale)
                kind: {
                    if (root.status === "error") return "close"
                    if (root.status === "success") return "check"
                    return "lock"
                }
                tint: {
                    if (root.status === "error") return "#f0708a"
                    if (root.status === "success") return "#34d399"
                    return pill.accent
                }
            }

            Text {
                text: {
                    if (root.status === "error") {
                        return (root.pam && root.pam.errorMessage !== "") ? root.pam.errorMessage : "Incorrect password"
                    }
                    if (root.status === "success") return "Unlocked"
                    if (root.status === "authenticating") return "Verifying credentials…"
                    return ""
                }
                color: {
                    if (root.status === "error") return "#fca5b5"
                    if (root.status === "success") return "#6ee7b7"
                    return "#e0f2fe"
                }
                font.family: root.themeStore ? root.themeStore.fontFamily : "JetBrains Mono"
                font.pixelSize: Math.round(11 * root.screenScale)
                font.weight: Font.Medium
            }
        }
    }
}
