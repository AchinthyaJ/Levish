import QtQuick
import QtQuick.Layouts
import "../../common" as C
import "../../common/Theme.js" as Theme
import "../../common" as Pal

Rectangle {
    id: root

    property var battery: ({ percent: 100, charging: false })
    property var themeStore: null
    property real screenScale: 1.0

    readonly property int pct: battery ? battery.percent : 100
    readonly property bool charging: battery ? battery.charging : false
    readonly property color accent: themeStore ? themeStore.accentColor : Pal.Palette.accent

    readonly property color statusColor: {
        if (charging) return "#34d399"
        if (pct <= 15) return "#f0708a"
        if (pct <= 30) return "#fb923c"
        return accent
    }

    implicitHeight: Math.round(32 * screenScale)
    implicitWidth: row.implicitWidth + Math.round(20 * screenScale)
    radius: height / 2

    color: "#121b25aa"
    border.color: "#25ffffff"
    border.width: 1

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(6 * root.screenScale)

        C.Icon {
            Layout.preferredWidth: Math.round(14 * root.screenScale)
            Layout.preferredHeight: Math.round(14 * root.screenScale)
            kind: root.charging ? "bolt" : "thermo"
            tint: root.statusColor
        }

        Text {
            text: root.pct + "%"
            color: "#f5f9fd"
            font.family: root.themeStore ? root.themeStore.fontFamily : "JetBrains Mono"
            font.pixelSize: Math.round(12 * root.screenScale)
            font.weight: Font.DemiBold
        }

        Text {
            visible: root.charging
            text: "Charging"
            color: "#6ee7b7"
            font.family: root.themeStore ? root.themeStore.fontFamily : "JetBrains Mono"
            font.pixelSize: Math.round(10 * root.screenScale)
        }
    }
}
