// One level of a tray app's menu, drawn in Levish's style. Submenus expand inline and recurse.
// Items come from Quickshell's QsMenuOpener, so the app's own menu structure is shown as-is.
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../common/Theme.js" as Theme
import "../common" as Pal

ColumnLayout {
    id: level
    property var menu            // the tray item's menu handle, or a parent entry for a submenu
    property int depth: 0
    signal done()                // an item was chosen: the whole menu should close
    spacing: 2

    QsMenuOpener {
        id: opener
        menu: level.menu
    }

    Repeater {
        model: opener.children
        delegate: ColumnLayout {
            id: entryCol
            required property var modelData
            readonly property var entry: modelData
            property bool expanded: false
            Layout.fillWidth: true
            spacing: 0

            // Separator
            Rectangle {
                visible: entry.isSeparator
                Layout.fillWidth: true
                Layout.preferredHeight: 9
                color: "transparent"
                Rectangle {
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 8; rightMargin: 8 }
                    height: 1
                    color: Pal.Palette.surfaceEdge
                }
            }

            // Item row
            Rectangle {
                visible: !entry.isSeparator
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? 30 : 0
                radius: 8
                color: rowMa.containsMouse && entry.enabled ? Pal.Palette.surfaceHover : "transparent"
                opacity: entry.enabled ? 1 : 0.45

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 10 + level.depth * 14
                        rightMargin: 10
                    }
                    spacing: 8

                    Image {
                        visible: entry.icon !== ""
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        source: entry.icon
                        sourceSize.width: 32
                        sourceSize.height: 32
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                    }

                    Text {
                        Layout.fillWidth: true
                        text: entry.text
                        color: Pal.Palette.textPrimary
                        font.pixelSize: Theme.fontSmall
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }

                    Text {
                        visible: entry.hasChildren
                        text: entryCol.expanded ? "⌄" : "›"
                        color: Pal.Palette.muted
                        font.pixelSize: Theme.fontBody
                    }
                }

                MouseArea {
                    id: rowMa
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: entry.enabled
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (entry.hasChildren) {
                            entryCol.expanded = !entryCol.expanded
                        } else {
                            entry.triggered()
                            level.done()
                        }
                    }
                }
            }

            // Submenu, expanded inline
            Loader {
                Layout.fillWidth: true
                active: entryCol.expanded
                source: "TrayMenuEntries.qml"
                onLoaded: {
                    item.menu = entryCol.entry
                    item.depth = level.depth + 1
                    // Choosing an item deep in a submenu closes the whole menu.
                    item.done.connect(level.done)
                }
            }
        }
    }
}
