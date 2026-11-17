import QtQuick
import QtQuick.Layouts
import "../../common" as C
import "../../common/Theme.js" as Theme
import "../../common" as Pal

Rectangle {
    id: root

    property var themeStore: null
    property date currentTime: new Date()
    property real scaleFactor: 1.0

    implicitHeight: Math.round(32 * scaleFactor)
    implicitWidth: contentRow.implicitWidth + Math.round(24 * scaleFactor)
    radius: height / 2

    color: "#141c2688"
    border.color: Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.145)
    border.width: 1

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: Math.round(8 * root.scaleFactor)

        C.Icon {
            Layout.preferredWidth: Math.round(14 * root.scaleFactor)
            Layout.preferredHeight: Math.round(14 * root.scaleFactor)
            kind: "moon"
            tint: root.themeStore ? root.themeStore.accentColor : Pal.Palette.accent
        }

        Text {
            id: dayText
            text: Qt.formatDate(root.currentTime, "dddd").toUpperCase()
            color: root.themeStore ? root.themeStore.accentColor : Pal.Palette.accent
            font.family: root.themeStore ? root.themeStore.fontFamily : "JetBrains Mono"
            font.pixelSize: Math.round(12 * root.scaleFactor)
            font.weight: Font.DemiBold
            font.letterSpacing: 1.2
        }

        Text {
            text: "•"
            color: "#60768e"
            font.pixelSize: Math.round(12 * root.scaleFactor)
        }

        Text {
            id: dateText
            text: Qt.formatDate(root.currentTime, "d MMMM yyyy").toUpperCase()
            color: "#e2ecf7"
            font.family: root.themeStore ? root.themeStore.fontFamily : "JetBrains Mono"
            font.pixelSize: Math.round(12 * root.scaleFactor)
            font.weight: Font.Medium
            font.letterSpacing: 1.0
        }
    }
}
