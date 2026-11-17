import QtQuick
import QtQuick.Controls
import "../../common/Theme.js" as Theme

// A colour from the configuration: a swatch and a hex field. Only a valid #rrggbb value is saved.
// `path` is the schema key (for example "palette.bar"); the field reads and writes it through the store.
Rectangle {
    id: field
    property var themeStore
    property string path: ""
    property string label: ""
    property color accent: Theme.accent

    readonly property string current: themeStore ? String(themeStore.valueOf(path)) : ""
    readonly property bool valid: /^#[0-9a-fA-F]{6}$/.test(input.text.trim())

    implicitHeight: 36
    implicitWidth: 180
    radius: 9
    color: Theme.controlFill
    border.color: input.activeFocus ? (valid ? accent : Theme.danger) : Theme.controlEdge

    Row {
        anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
        spacing: 8
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 20; height: 20; radius: 6
            color: field.valid ? input.text.trim() : field.current
            border.color: Theme.controlEdge
            border.width: 1
        }
        TextField {
            id: input
            width: parent.width - 28
            anchors.verticalCenter: parent.verticalCenter
            text: field.current
            placeholderText: "#rrggbb"
            placeholderTextColor: Theme.muted
            color: Theme.text
            font.pixelSize: Theme.fs(12)
            font.family: "monospace"
            background: Item {}
            // Keep the text in step with the stored value when a preset or import changes it.
            Connections {
                target: field
                function onCurrentChanged() { if (!input.activeFocus) input.text = field.current }
            }
            onEditingFinished: {
                if (field.valid) field.themeStore.set(field.path, text.trim().toLowerCase())
                else text = field.current
            }
        }
    }
}
