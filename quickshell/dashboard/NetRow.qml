import QtQuick
import QtQuick.Layouts
import "../common" as C
import "../common/Theme.js" as Theme
import "../common" as Pal

RowLayout {
    property string label: ""
    property string value: ""
    Layout.fillWidth: true
    Text { text: label; color: Pal.Palette.muted; font.pixelSize: Theme.fs(10); Layout.fillWidth: true }
    Text { text: value; color: Theme.network; font.pixelSize: Theme.fs(10); font.family: "JetBrains Mono" }
}
