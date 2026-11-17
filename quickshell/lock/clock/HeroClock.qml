import QtQuick
import QtQuick.Layouts
import "../../common" as C
import "../../common/Theme.js" as Theme
import "../../common" as Pal

ColumnLayout {
    id: root

    property var themeStore: null
    property real screenScale: 1.0
    property int alignment: Qt.AlignHCenter // Qt.AlignLeft, Qt.AlignHCenter, Qt.AlignRight

    readonly property real finalScale: screenScale * (themeStore ? themeStore.lockClockScale : 1.0)
    readonly property bool is12Hour: (themeStore ? themeStore.lockClockFormat : "HH:mm").indexOf("AP") >= 0 || (themeStore ? themeStore.lockClockFormat : "HH:mm").indexOf("ap") >= 0
    readonly property bool showSeconds: themeStore ? themeStore.lockShowSeconds : false
    readonly property string family: themeStore ? themeStore.fontFamily : "JetBrains Mono"
    readonly property color accent: themeStore ? themeStore.accentColor : Pal.Palette.accent

    property date now: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    spacing: Math.round(14 * root.finalScale)

    // Main Clock Digits Row
    RowLayout {
        Layout.alignment: root.alignment
        spacing: Math.round(8 * root.finalScale)

        // Hours
        Text {
            id: hoursText
            text: Qt.formatTime(root.now, root.is12Hour ? "hh" : "HH")
            color: "#f5f9fd"
            font.family: root.family
            font.pixelSize: Math.round(92 * root.finalScale)
            font.weight: Font.Bold
            font.letterSpacing: -1.5
        }

        // Breathing Colon
        Text {
            id: colonText
            text: ":"
            color: root.accent
            font.family: root.family
            font.pixelSize: Math.round(86 * root.finalScale)
            font.weight: Font.Medium

            SequentialAnimation on opacity {
                running: !(root.themeStore && root.themeStore.lockReducedMotion)
                loops: Animation.Infinite
                NumberAnimation { to: 0.35; duration: Theme.dur(1000); easing.type: Easing.InOutQuad }
                NumberAnimation { to: 1.0; duration: Theme.dur(1000); easing.type: Easing.InOutQuad }
            }
        }

        // Minutes (tinted with accent color for magnificent contrast)
        Text {
            id: minutesText
            text: Qt.formatTime(root.now, "mm")
            color: root.accent
            font.family: root.family
            font.pixelSize: Math.round(92 * root.finalScale)
            font.weight: Font.Bold
            font.letterSpacing: -1.5
        }

        // Optional Column for AM/PM and Seconds
        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: Math.round(6 * root.finalScale)
            spacing: Math.round(6 * root.finalScale)
            visible: root.is12Hour || root.showSeconds

            // AM/PM badge
            Rectangle {
                visible: root.is12Hour
                implicitWidth: Math.round(42 * root.finalScale)
                implicitHeight: Math.round(26 * root.finalScale)
                radius: Math.round(7 * root.finalScale)
                color: "#162432"
                border.color: root.accent
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: Qt.formatTime(root.now, "AP")
                    color: root.accent
                    font.family: root.family
                    font.pixelSize: Math.round(12 * root.finalScale)
                    font.weight: Font.Bold
                }
            }

            // Seconds badge
            Rectangle {
                visible: root.showSeconds
                implicitWidth: Math.round(42 * root.finalScale)
                implicitHeight: Math.round(26 * root.finalScale)
                radius: Math.round(7 * root.finalScale)
                color: "#12ffffff"
                border.color: "#25ffffff"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: Qt.formatTime(root.now, "ss")
                    color: "#9fb0c6"
                    font.family: root.family
                    font.pixelSize: Math.round(12 * root.finalScale)
                    font.weight: Font.DemiBold
                }
            }
        }
    }

    // Date Badge presentation
    DateBadge {
        Layout.alignment: root.alignment
        themeStore: root.themeStore
        currentTime: root.now
        scaleFactor: root.finalScale
    }
}
