import QtQuick
import QtQuick.Layouts
import "../../common" as C
import "../../common/Theme.js" as Theme

Rectangle {
    id: root

    property var weatherData: null
    property var themeStore: null
    property real screenScale: 1.0

    readonly property bool isFahrenheit: (themeStore && themeStore.lockWeatherUnits === "F")
    readonly property string tempStr: {
        if (!weatherData) return "--"
        const val = isFahrenheit ? weatherData.temp_f : weatherData.temp_c
        return val + (isFahrenheit ? "°F" : "°C")
    }
    readonly property string conditionStr: (weatherData && weatherData.condition) ? weatherData.condition : "Clear"
    readonly property string locationStr: (weatherData && weatherData.location) ? weatherData.location : ""

    readonly property string iconKind: {
        const c = conditionStr.toLowerCase()
        if (c.indexOf("rain") >= 0 || c.indexOf("drizzle") >= 0 || c.indexOf("shower") >= 0) return "down"
        if (c.indexOf("cloud") >= 0 || c.indexOf("overcast") >= 0) return "moon"
        if (c.indexOf("snow") >= 0 || c.indexOf("ice") >= 0) return "thermo"
        if (c.indexOf("thunder") >= 0 || c.indexOf("storm") >= 0) return "bolt"
        return "sun"
    }

    implicitHeight: Math.round(36 * screenScale)
    implicitWidth: row.implicitWidth + Math.round(24 * screenScale)
    radius: height / 2

    color: "#121b25aa"
    border.color: "#25ffffff"
    border.width: 1

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(8 * root.screenScale)

        C.Icon {
            Layout.preferredWidth: Math.round(16 * root.screenScale)
            Layout.preferredHeight: Math.round(16 * root.screenScale)
            kind: root.iconKind
            tint: root.themeStore ? root.themeStore.accentColor : "#c8f7ef"
        }

        Text {
            text: root.tempStr
            color: "#f5f9fd"
            font.family: root.themeStore ? root.themeStore.fontFamily : "JetBrains Mono"
            font.pixelSize: Math.round(13 * root.screenScale)
            font.weight: Font.Bold
        }

        Text {
            text: "•"
            color: "#546a80"
            font.pixelSize: Math.round(11 * root.screenScale)
        }

        Text {
            text: root.conditionStr
            color: "#c2d3e4"
            font.family: root.themeStore ? root.themeStore.fontFamily : "JetBrains Mono"
            font.pixelSize: Math.round(12 * root.screenScale)
            font.weight: Font.Medium
            elide: Text.ElideRight
            Layout.maximumWidth: Math.round(140 * root.screenScale)
        }

        Text {
            visible: root.locationStr !== ""
            text: "(" + root.locationStr + ")"
            color: "#7e95ab"
            font.family: root.themeStore ? root.themeStore.fontFamily : "JetBrains Mono"
            font.pixelSize: Math.round(11 * root.screenScale)
            elide: Text.ElideRight
            Layout.maximumWidth: Math.round(100 * root.screenScale)
        }
    }
}
