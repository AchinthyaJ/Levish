// Time over date, stacked. Responsive to user themeStore settings.
import QtQuick
import "../common/Theme.js" as Theme

Column {
    id: clock
    property var themeStore: null
    spacing: -2
    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: clock.now = new Date() }

    Text {
        anchors.right: parent.right
        text: {
            const fmt = (themeStore && themeStore.clockFormat) ? themeStore.clockFormat : "HH:mm"
            const withSec = (themeStore && themeStore.showSeconds) ? (fmt + ":ss") : fmt
            return Qt.formatTime(clock.now, withSec)
        }
        color: Theme.text
        font.family: (themeStore && themeStore.fontFamily) ? themeStore.fontFamily : "JetBrains Mono"
        font.pixelSize: 14
        font.weight: Font.Bold
    }
    Text {
        anchors.right: parent.right
        visible: themeStore ? themeStore.showDate : true
        text: Qt.formatDate(clock.now, "ddd d MMM").toUpperCase()
        color: Theme.muted
        font.family: (themeStore && themeStore.fontFamily) ? themeStore.fontFamily : "JetBrains Mono"
        font.pixelSize: 9
        font.letterSpacing: 1
    }
}
