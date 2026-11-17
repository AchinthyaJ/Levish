import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../components"
import "../../common/Theme.js" as Theme
import "../../common" as Pal

// Clipboard history settings and the history itself. The history is kept in memory only.
Flickable {
    id: page
    property var themeStore
    property var clipboard              // ClipboardService
    property string pageId: ""
    ScrollBar.vertical: PageScrollBar { accent: page.themeStore.accentColor }
    property string keywords: "clipboard history copy paste pin clear privacy text"
    readonly property var resetPaths: ["clipboard.enabled", "clipboard.max_items"]
    readonly property color accent: themeStore.accentColor

    contentHeight: col.implicitHeight + 40
    clip: true

    ColumnLayout {
        id: col
        x: Theme.space5; y: Theme.space4
        width: page.width - Theme.space5 * 2
        spacing: Theme.space3

        SettingsCard {
            title: "History"
            SettingsRow {
                label: "Record what I copy"
                hint: "Off by default. While off, nothing is recorded. History lives in memory only and is cleared when the shell restarts."
                SettingsToggle { accent: page.accent; checked: page.themeStore.clipboardEnabled
                    onToggled: (v) => page.themeStore.set("clipboard.enabled", v) }
            }
            SettingsRow {
                label: "Items kept"
                hint: "Pinned items are never removed to make room."
                SettingsSlider { from: 5; to: 200; step: 5; accent: page.accent
                    value: page.themeStore.clipboardMax
                    onCommitted: (v) => page.themeStore.set("clipboard.max_items", Math.round(v)) }
            }
            SettingsRow {
                label: page.clipboard && page.clipboard.status === "unavailable"
                    ? "Clipboard watcher unavailable"
                    : (page.clipboard && page.clipboard.entries.length > 0
                        ? (page.clipboard.entries.length + " item" + (page.clipboard.entries.length === 1 ? "" : "s"))
                        : "Nothing recorded yet")
                hint: page.clipboard && page.clipboard.status === "unavailable"
                    ? "Needs wl-clipboard (wl-paste and wl-copy) installed."
                    : "Only text is recorded. Copies over 20 000 characters are skipped."
                SettingsButton {
                    text: "Clear unpinned"
                    enabled: page.clipboard && page.clipboard.entries.some(e => !e.pinned)
                    onClicked: page.clipboard.clearUnpinned()
                }
            }
        }

        SettingsCard {
            title: "Items"
            Repeater {
                model: page.clipboard ? page.clipboard.entries : []
                delegate: Rectangle {
                    required property var modelData
                    width: parent ? parent.width : 300
                    implicitHeight: row.implicitHeight + 16
                    radius: Theme.radiusRow
                    color: Pal.Palette.controlFill
                    border.color: modelData.pinned ? page.accent : Pal.Palette.surfaceEdge

                    RowLayout {
                        id: row
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                        spacing: 10
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                Layout.fillWidth: true
                                text: modelData.text.replace(/\s+/g, " ")
                                color: Pal.Palette.textPrimary
                                font.pixelSize: Theme.fontSmall
                                elide: Text.ElideRight
                                textFormat: Text.PlainText
                            }
                            Text {
                                text: modelData.time + (modelData.pinned ? "  ·  pinned" : "")
                                color: Pal.Palette.muted
                                font.pixelSize: Theme.fontCaption
                            }
                        }
                        SettingsButton { text: "Copy"; onClicked: page.clipboard.copyBack(modelData.text) }
                        SettingsButton { text: modelData.pinned ? "Unpin" : "Pin"; onClicked: page.clipboard.togglePin(modelData.text) }
                        SettingsButton { text: "Delete"; danger: true; onClicked: page.clipboard.remove(modelData.text) }
                    }
                }
            }
            Text {
                visible: page.clipboard && page.clipboard.entries.length === 0
                Layout.fillWidth: true
                text: page.themeStore.clipboardEnabled
                    ? "Copy some text and it will appear here."
                    : "Turn on \"Record what I copy\" to start a history."
                color: Pal.Palette.muted
                font.pixelSize: Theme.fontSmall
                wrapMode: Text.Wrap
            }
        }
    }
}
