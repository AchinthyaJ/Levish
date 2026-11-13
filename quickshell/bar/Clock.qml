// Time over date, stacked. Time turns the accent color on hover.
import QtQuick
import "../common/Theme.js" as Theme

Column {
    id: clock
    spacing: -2
    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: clock.now = new Date() }

    Text {
        anchors.right: parent.right
        text: Qt.formatTime(clock.now, "HH:mm")
        color: Theme.text
        font.family: "JetBrains Mono"; font.pixelSize: 15; font.weight: Font.Bold
    }
    Text {
        anchors.right: parent.right
        text: Qt.formatDate(clock.now, "ddd d MMM").toUpperCase()
        color: Theme.muted
        font.family: "JetBrains Mono"; font.pixelSize: 9; font.letterSpacing: 1
    }
}
