// Battery row: battery icon, status, level bar.  Read-only — no toggles.
import QtQuick
import QtQuick.Layouts
import "../bar" as B
import "../common/Theme.js" as Theme
import "../common" as Pal

RowLayout {
    id: row
    property var battery: ({ percent: 0, charging: false })
    spacing: 12
    Layout.fillWidth: true

    B.BatteryIcon {
        Layout.preferredWidth: 28; Layout.preferredHeight: 18
        level: row.battery.percent
        charging: row.battery.charging
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        RowLayout {
            Layout.fillWidth: true
            Text { text: "Battery"; color: Pal.Palette.text; font.pixelSize: Theme.fs(13); font.weight: Font.Medium; Layout.fillWidth: true }
            Text {
                text: row.battery.percent + "%"
                color: Pal.Palette.muted; font.pixelSize: Theme.fs(11); font.family: "JetBrains Mono"
            }
        }
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 4; radius: 2
            color: Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.133)
            Rectangle {
                width: parent.width * Math.min(1, row.battery.percent / 100)
                height: parent.height; radius: 2
                color: row.battery.charging ? "#86efac" : (row.battery.percent < 20 ? "#e94560" : Pal.Palette.accent)
                Behavior on width { NumberAnimation { duration: Theme.dur(600); easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: Theme.dur(300) } }
            }
        }
        Text {
            text: row.battery.charging ? "Charging" : (row.battery.percent < 20 ? "Low battery" : "Discharging")
            color: Pal.Palette.muted; font.pixelSize: Theme.fs(10)
        }
    }
}
