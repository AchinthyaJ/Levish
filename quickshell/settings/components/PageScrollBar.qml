import QtQuick
import QtQuick.Controls
import "../../common/Theme.js" as Theme

// Vertical scroll slider for a settings page. Attach it with
//   ScrollBar.vertical: PageScrollBar { accent: page.themeStore.accentColor }
// on a Flickable. It only appears when the page is taller than the window.
ScrollBar {
    id: bar
    property color accent: "#4fd1c5"

    policy: ScrollBar.AsNeeded
    interactive: true
    minimumSize: 0.08
    width: 10
    padding: 2

    contentItem: Rectangle {
        implicitWidth: 6
        radius: 3
        color: bar.pressed ? bar.accent : (bar.hovered ? Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.7)
                                                        : Qt.rgba(1, 1, 1, 0.22))
        opacity: bar.policy === ScrollBar.AlwaysOn || bar.active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.dur(180) } }
        Behavior on color { ColorAnimation { duration: Theme.dur(140) } }
    }
    background: Rectangle {
        implicitWidth: 6
        radius: 3
        color: Qt.rgba(1, 1, 1, 0.05)
        opacity: bar.active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.dur(180) } }
    }
}
