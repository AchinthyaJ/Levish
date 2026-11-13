// Battery row: battery icon, status, level bar.  Read-only — no toggles.
import QtQuick
import QtQuick.Layouts
import "../bar" as B
import "../common/Theme.js" as Theme

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
            Text { text: "Battery"; color: Theme.text; font.pixelSize: 13; font.weight: Font.Medium; Layout.fillWidth: true }
            Text {
                text: row.battery.percent + "%"
                color: Theme.muted; font.pixelSize: 11; font.family: "JetBrains Mono"
            }
        }
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 4; radius: 2
            color: "#22ffffff"
            Rectangle {
                width: parent.width * Math.min(1, row.battery.percent / 100)
                height: parent.height; radius: 2
                color: row.battery.charging ? "#86efac" : (row.battery.percent < 20 ? "#e94560" : Theme.accent)
                Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 300 } }
            }
        }
        Text {
            text: row.battery.charging ? "Charging" : (row.battery.percent < 20 ? "Low battery" : "Discharging")
            color: Theme.muted; font.pixelSize: 10
        }
    }
}
