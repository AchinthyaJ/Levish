import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../components"
import "../../common/Theme.js" as Theme
import "../../common" as Pal

// Notification settings. Popup options are saved to config.json; do-not-disturb is runtime state
// and resets when the shell restarts.
Flickable {
    id: page
    property var themeStore
    property var notifications          // NotificationService
    property string pageId: ""
    ScrollBar.vertical: PageScrollBar { accent: page.themeStore.accentColor }
    property string keywords: "notifications notification popup toast timeout position history do not disturb dnd clear"
    readonly property var resetPaths: ["notifications.enabled", "notifications.timeout_ms", "notifications.position", "notifications.max_visible"]
    readonly property color accent: themeStore.accentColor

    readonly property var positionOptions: [
        { value: "top-right", label: "Top right" }, { value: "top-left", label: "Top left" },
        { value: "bottom-right", label: "Bottom right" }, { value: "bottom-left", label: "Bottom left" }
    ]

    contentHeight: col.implicitHeight + 40
    clip: true

    ColumnLayout {
        id: col
        x: Theme.space5; y: Theme.space4
        width: page.width - Theme.space5 * 2
        spacing: Theme.space3

        SettingsCard {
            title: "Popups"
            SettingsRow {
                label: "Show notification popups"
                hint: "Off keeps notifications in the history without showing popups."
                SettingsToggle { accent: page.accent; checked: page.themeStore.notificationsEnabled
                    onToggled: (v) => page.themeStore.set("notifications.enabled", v) }
            }
            SettingsRow {
                label: "Do not disturb"
                hint: "Hides popups for this session. Notifications still go to the history."
                SettingsToggle { accent: page.accent; checked: page.notifications ? page.notifications.doNotDisturb : false
                    onToggled: (v) => { if (page.notifications) page.notifications.setDoNotDisturb(v) } }
            }
            SettingsRow {
                label: "Position"
                SettingsChoice { accent: page.accent; options: page.positionOptions
                    current: page.themeStore.notificationPosition
                    onPicked: (v) => page.themeStore.set("notifications.position", v) }
            }
            SettingsRow {
                label: "Time before a popup closes"
                hint: "Critical notifications stay until you dismiss them. Hovering pauses the timer."
                SettingsSlider { from: 1; to: 60; step: 1; suffix: " s"; accent: page.accent
                    value: page.themeStore.notificationTimeout / 1000
                    onCommitted: (v) => page.themeStore.set("notifications.timeout_ms", Math.round(v * 1000)) }
            }
            SettingsRow {
                label: "Popups shown at once"
                SettingsSlider { from: 1; to: 6; step: 1; accent: page.accent
                    value: page.themeStore.notificationMaxVisible
                    onCommitted: (v) => page.themeStore.set("notifications.max_visible", Math.round(v)) }
            }
        }

        SettingsCard {
            title: "History"
            SettingsRow {
                label: page.notifications && page.notifications.history.length > 0
                    ? (page.notifications.history.length + " recent notification" + (page.notifications.history.length === 1 ? "" : "s"))
                    : "No notifications yet"
                hint: "Kept for this session only, up to " + (page.notifications ? page.notifications.historyLimit : 100) + " entries."
                SettingsButton {
                    text: "Clear history"
                    enabled: page.notifications && page.notifications.history.length > 0
                    onClicked: page.notifications.clearHistory()
                }
            }
            Repeater {
                model: page.notifications ? page.notifications.history.slice(0, 30) : []
                delegate: Rectangle {
                    required property var modelData
                    // The card is a plain Column, so set the width explicitly.
                    width: parent ? parent.width : 300
                    implicitHeight: entryCol.implicitHeight + 16
                    radius: Theme.radiusRow
                    color: Pal.Palette.controlFill
                    border.color: Pal.Palette.surfaceEdge
                    ColumnLayout {
                        id: entryCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                        spacing: 2
                        RowLayout {
                            Layout.fillWidth: true
                            Text { Layout.fillWidth: true; text: modelData.app; color: Pal.Palette.muted; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold; elide: Text.ElideRight }
                            Text {
                                text: modelData.time + "  ·  " + (modelData.status === "suppressed" ? "not shown (" + modelData.reason + ")" : "shown")
                                color: Pal.Palette.muted; font.pixelSize: Theme.fontCaption
                            }
                        }
                        Text { Layout.fillWidth: true; text: modelData.summary; color: Pal.Palette.textPrimary; font.pixelSize: Theme.fontSmall; font.weight: Font.DemiBold; elide: Text.ElideRight; textFormat: Text.PlainText }
                        Text { visible: text !== ""; Layout.fillWidth: true; text: modelData.body; color: Pal.Palette.textSecondary; font.pixelSize: Theme.fontCaption; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight; textFormat: Text.PlainText }
                    }
                }
            }
        }
    }
}
