import QtQuick
import QtQuick.Layouts
import "../../common" as C
import "../../common/Theme.js" as Theme
import "../../common" as Pal

Rectangle {
    id: root

    required property var pam
    property var themeStore: null
    property real screenScale: 1.0
    property bool showPassword: false

    property real shakeOffset: 0

    implicitWidth: Math.round(340 * screenScale)
    implicitHeight: Math.round(48 * screenScale)
    radius: height / 2

    transform: Translate { x: root.shakeOffset }

    // Damped shake animation on authentication failure
    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: root; property: "shakeOffset"; to: -12; duration: Theme.dur(55); easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "shakeOffset"; to: 12; duration: Theme.dur(60); easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "shakeOffset"; to: -8; duration: Theme.dur(60); easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "shakeOffset"; to: 8; duration: Theme.dur(65); easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "shakeOffset"; to: -4; duration: Theme.dur(50); easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "shakeOffset"; to: 0; duration: Theme.dur(50); easing.type: Easing.InQuad }
    }

    Connections {
        target: root.pam
        function onFailed() {
            shakeAnim.restart()
        }
    }

    readonly property bool isError: root.pam && root.pam.status === "error"
    readonly property bool isAuth: root.pam && root.pam.status === "authenticating"
    readonly property color accent: root.themeStore ? root.themeStore.accentColor : Pal.Palette.accent

    color: isError ? "#281a20" : "#121b24cc"
    border.color: isError ? "#f0708a" : (root.pam && root.pam.buffer.length > 0 ? root.accent : "#30ffffff")
    border.width: (isError || (root.pam && root.pam.buffer.length > 0)) ? 1.5 : 1

    Behavior on border.color { ColorAnimation { duration: Theme.dur(180) } }
    Behavior on color { ColorAnimation { duration: Theme.dur(180) } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Math.round(14 * root.screenScale)
        anchors.rightMargin: Math.round(8 * root.screenScale)
        spacing: Math.round(10 * root.screenScale)

        // Leading Lock icon / Spinner
        Item {
            Layout.preferredWidth: Math.round(20 * root.screenScale)
            Layout.preferredHeight: Math.round(20 * root.screenScale)

            C.Icon {
                anchors.centerIn: parent
                width: parent.width; height: parent.height
                kind: "lock"
                tint: root.isError ? "#f0708a" : (root.pam && root.pam.buffer.length > 0 ? root.accent : "#8ca0b8")
                visible: !root.isAuth
            }

            // Spinner during PAM auth
            Rectangle {
                id: spinner
                anchors.centerIn: parent
                width: parent.width; height: parent.height
                radius: width / 2
                color: "transparent"
                border.color: root.accent
                border.width: 2
                visible: root.isAuth

                RotationAnimation on rotation {
                    running: root.isAuth
                    loops: Animation.Infinite
                    from: 0; to: 360; duration: Theme.dur(800)
                }
            }
        }

        // Masked Password or Placeholder
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Placeholder
            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Enter password…"
                color: "#62788e"
                font.family: root.themeStore ? root.themeStore.fontFamily : "JetBrains Mono"
                font.pixelSize: Math.round(13 * root.screenScale)
                font.italic: true
                visible: !(root.pam && root.pam.buffer.length > 0)
            }

            // Masked bullets or plain text
            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    if (!root.pam || root.pam.buffer.length === 0) return ""
                    if (root.showPassword) return root.pam.buffer
                    // Bullets with stylish spacing
                    return "●".repeat(root.pam.buffer.length)
                }
                color: "#f5f9fd"
                font.family: root.showPassword ? (root.themeStore ? root.themeStore.fontFamily : "JetBrains Mono") : "sans-serif"
                font.pixelSize: root.showPassword ? Math.round(14 * root.screenScale) : Math.round(16 * root.screenScale)
                font.letterSpacing: root.showPassword ? 1.0 : 3.0
                font.weight: Font.Medium
                elide: Text.ElideLeft
                width: parent.width
                visible: root.pam && root.pam.buffer.length > 0
            }
        }

        // Show/Hide password toggle button
        Rectangle {
            Layout.preferredWidth: Math.round(28 * root.screenScale)
            Layout.preferredHeight: Math.round(28 * root.screenScale)
            radius: width / 2
            color: eyeMA.containsMouse ? "#20ffffff" : "transparent"
            visible: root.pam && root.pam.buffer.length > 0

            C.Icon {
                anchors.centerIn: parent
                width: Math.round(16 * root.screenScale)
                height: Math.round(16 * root.screenScale)
                kind: root.showPassword ? "check" : "moon"
                tint: eyeMA.containsMouse ? root.accent : "#8ca0b8"
            }

            MouseArea {
                id: eyeMA
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.showPassword = !root.showPassword
            }
        }

        // Submit arrow button
        Rectangle {
            Layout.preferredWidth: Math.round(32 * root.screenScale)
            Layout.preferredHeight: Math.round(32 * root.screenScale)
            radius: width / 2
            color: (root.pam && root.pam.buffer.length > 0)
                   ? (submitMA.containsMouse ? Qt.lighter(root.accent, 1.1) : root.accent)
                   : (submitMA.containsMouse ? "#28ffffff" : "#18ffffff")

            Behavior on color { ColorAnimation { duration: Theme.dur(150) } }

            Text {
                anchors.centerIn: parent
                text: "➔"
                color: (root.pam && root.pam.buffer.length > 0) ? "#0e141a" : "#72889e"
                font.pixelSize: Math.round(13 * root.screenScale)
                font.weight: Font.Bold
            }

            MouseArea {
                id: submitMA
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.pam) root.pam.submit()
                }
            }
        }
    }
}
