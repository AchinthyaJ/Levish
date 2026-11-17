// Notification popups: one layer-shell window in the configured corner, showing the tracked
// notifications from NotificationService. Critical notifications stay until dismissed; the rest
// expire after the Settings timeout, or the app's own timeout if it sets one.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "../common/Theme.js" as Theme
import "../common" as Pal

PanelWindow {
    id: win
    required property var service      // NotificationService
    required property var themeStore   // ThemeStore

    readonly property string corner: themeStore.notificationPosition
    readonly property bool top: corner.indexOf("top") === 0
    readonly property bool leftSide: corner.indexOf("left") >= 0

    visible: themeStore.notificationsEnabled && service.liveCount > 0
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.namespace: "levish-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    anchors { top: top; bottom: !top; left: leftSide; right: !leftSide }
    // Clear the top bar when the popups sit at the top.
    margins { top: top ? 52 : 0; bottom: top ? 0 : 12; left: leftSide ? 12 : 0; right: leftSide ? 0 : 12 }
    implicitWidth: 380
    implicitHeight: list.implicitHeight + 24

    Column {
        id: list
        x: 12; y: 12
        width: 356
        spacing: 10

        Repeater {
            model: win.service.server.trackedNotifications
            delegate: Rectangle {
                id: card
                required property var modelData
                required property int index
                readonly property var n: modelData
                readonly property bool critical: n.urgency === NotificationUrgency.Critical

                visible: index < win.themeStore.notificationMaxVisible
                width: 356
                implicitHeight: body.implicitHeight + 24
                radius: 16
                color: Pal.Palette.glass
                border.color: critical ? Pal.Palette.danger : Pal.Palette.glassEdge
                border.width: 1

                // Expiry. Hovering pauses it, so a notification you are reading does not vanish.
                Timer {
                    running: card.visible && !card.critical && !hoverArea.containsMouse
                    interval: card.n.expireTimeout > 0 ? card.n.expireTimeout : win.themeStore.notificationTimeout
                    onTriggered: card.n.expire()
                }

                MouseArea {
                    id: hoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }

                ColumnLayout {
                    id: body
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Image {
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            source: Quickshell.iconPath(card.n.appIcon || card.n.desktopEntry, "dialog-information")
                            sourceSize.width: 32
                            sourceSize.height: 32
                            asynchronous: true
                        }
                        Text {
                            Layout.fillWidth: true
                            text: card.n.appName || card.n.desktopEntry || "Application"
                            color: Pal.Palette.muted
                            font.pixelSize: Theme.fontCaption
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        Rectangle {
                            width: 20; height: 20; radius: 10
                            color: closeMa.containsMouse ? Pal.Palette.surfaceHover : "transparent"
                            Text { anchors.centerIn: parent; text: "×"; color: Pal.Palette.textSecondary; font.pixelSize: Theme.fs(14) }
                            MouseArea {
                                id: closeMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: card.n.dismiss()
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: card.n.summary
                        color: Pal.Palette.textPrimary
                        font.pixelSize: Theme.fontBody
                        font.weight: Font.DemiBold
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }

                    Text {
                        visible: text !== ""
                        Layout.fillWidth: true
                        text: card.n.body
                        color: Pal.Palette.textSecondary
                        font.pixelSize: Theme.fontSmall
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: card.n.actions.length > 0
                        Repeater {
                            model: card.n.actions
                            delegate: Rectangle {
                                required property var modelData
                                height: 26
                                width: actionText.implicitWidth + 20
                                radius: 8
                                color: actionMa.containsMouse ? Pal.Palette.surfaceHover : Pal.Palette.controlFill
                                border.color: Pal.Palette.controlEdge
                                Text {
                                    id: actionText
                                    anchors.centerIn: parent
                                    text: modelData.text
                                    color: Pal.Palette.textPrimary
                                    font.pixelSize: Theme.fontSmall
                                }
                                MouseArea {
                                    id: actionMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: modelData.invoke()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
