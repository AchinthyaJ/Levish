import QtQuick
import QtQuick.Layouts
import "../common" as C
import "../common/Theme.js" as Theme

RowLayout {
    property string label: ""
    property string value: ""
    Layout.fillWidth: true
    Text { text: label; color: Theme.muted; font.pixelSize: 10; Layout.fillWidth: true }
    Text { text: value; color: Theme.network; font.pixelSize: 10; font.family: "JetBrains Mono" }
}
