// Levish Settings — a normal, centered, resizable window (not a fullscreen overlay).
// Window decorations and placement come from Hyprland. Every control writes through the
// ThemeStore config service, so the shell reacts to each change.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../common" as C
import "../common/Theme.js" as Theme
import "components"
import "pages"

FloatingWindow {
    id: win
    required property var themeStore
    property bool open: false
    signal closeRequested()

    // Never shown at startup: the window only appears when `open` is set.
    visible: false

    title: "Levish Settings"
    implicitWidth: 980
    implicitHeight: 660
    minimumSize: Qt.size(720, 480)
    color: "#14161c"

    // The window is shown when `open` is set. Closing it from the compositor clears `open`.
    onOpenChanged: visible = open
    onVisibleChanged: if (!visible && win.open) win.closeRequested()

    readonly property color accent: themeStore.accentColor
    property string currentId: "overview"
    property string query: ""

    readonly property var pageList: [
        { id: "overview",   title: "Overview",               icon: "grid" },
        { id: "appearance", title: "Appearance",             icon: "sun" },
        { id: "topbar",     title: "Top Bar",                icon: "up" },
        { id: "dock",       title: "Dock",                   icon: "down" },
        { id: "launcher",   title: "Application Launcher",   icon: "apps" },
        { id: "wallpaper",  title: "Wallpaper",              icon: "grid" },
        { id: "about",      title: "About Levish",           icon: "note" }
    ]

    function pageItem(id) {
        for (let i = 0; i < pageStack.children.length; i++) if (pageStack.children[i].pageId === id) return pageStack.children[i]
        return null
    }
    readonly property var currentPage: pageItem(currentId)

    // Matches on page title and the keywords each page declares.
    readonly property var results: {
        const q = query.trim().toLowerCase()
        if (q === "") return []
        return pageList.filter(p => {
            const pg = pageItem(p.id)
            const hay = (p.title + " " + (pg ? pg.keywords : "")).toLowerCase()
            return hay.indexOf(q) >= 0
        })
    }

    function go(id) { currentId = id; query = "" }

    Rectangle {
        anchors.fill: parent
        color: "#14161c"
        focus: win.open
        Keys.onEscapePressed: win.closeRequested()

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ── Sidebar ────────────────────────────────────────────────
            Rectangle {
                Layout.preferredWidth: 232
                Layout.fillHeight: true
                color: "#0f1116"

                Rectangle { anchors { right: parent.right; top: parent.top; bottom: parent.bottom } width: 1; color: "#18ffffff" }

                ColumnLayout {
                    anchors { fill: parent; margins: 16 }
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 10
                        spacing: 10
                        Rectangle {
                            width: 34; height: 34; radius: 11
                            color: "#1f2a33"
                            border.color: win.accent; border.width: 1
                            C.Icon { anchors.centerIn: parent; width: 18; height: 18; kind: "gear"; tint: win.accent }
                        }
                        ColumnLayout {
                            spacing: 0
                            Text { text: "Settings"; color: Theme.text; font.pixelSize: 15; font.weight: Font.Bold }
                            Text { text: "Levish"; color: Theme.muted; font.pixelSize: 10 }
                        }
                    }

                    // Search across pages and their settings.
                    Rectangle {
                        Layout.fillWidth: true
                        height: 32; radius: 9
                        color: "#14ffffff"
                        border.color: search.activeFocus ? win.accent : "#22ffffff"
                        TextField {
                            id: search
                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            placeholderText: "Search settings"
                            placeholderTextColor: Theme.muted
                            color: Theme.text
                            font.pixelSize: 12
                            background: Item {}
                            text: win.query
                            onTextChanged: win.query = text
                            Keys.onEscapePressed: { if (text !== "") text = ""; else win.closeRequested() }
                        }
                    }

                    Repeater {
                        model: win.query.trim() !== "" ? win.results : win.pageList
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 36; radius: 9
                            readonly property bool selected: win.query.trim() === "" && win.currentId === modelData.id
                            color: selected ? Qt.rgba(win.accent.r, win.accent.g, win.accent.b, 0.16)
                                 : (navMa.containsMouse ? "#14ffffff" : "transparent")
                            Rectangle {
                                visible: parent.selected
                                width: 3; height: 18; radius: 2
                                color: win.accent
                                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                            }
                            RowLayout {
                                anchors { fill: parent; leftMargin: 12; rightMargin: 10 }
                                spacing: 10
                                C.Icon { width: 16; height: 16; kind: modelData.icon; tint: selected ? win.accent : Theme.muted }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.title
                                    color: selected ? Theme.text : Theme.muted
                                    font.pixelSize: 13
                                    font.weight: selected ? Font.DemiBold : Font.Normal
                                    elide: Text.ElideRight
                                }
                            }
                            MouseArea {
                                id: navMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.go(modelData.id)
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Text {
                        Layout.fillWidth: true
                        text: win.themeStore.status === "ok" ? "Saved to config/config.json"
                            : (win.themeStore.status === "missing" ? "No config file yet" : "Config needs attention")
                        color: win.themeStore.status === "ok" ? Theme.muted : "#f0708a"
                        font.pixelSize: 10
                        wrapMode: Text.Wrap
                    }
                }
            }

            // ── Content ────────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    Layout.leftMargin: 24
                    Layout.rightMargin: 16
                    Text {
                        Layout.fillWidth: true
                        text: win.pageList.filter(p => p.id === win.currentId)[0].title
                        color: Theme.text
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }
                    SettingsButton {
                        visible: win.currentPage && win.currentPage.resetPaths.length > 0
                        text: "Reset this page"
                        onClicked: win.themeStore.resetPaths(win.currentPage.resetPaths)
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#18ffffff" }

                StackLayout {
                    id: pageStack
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: Math.max(0, win.pageList.findIndex(p => p.id === win.currentId))

                    Overview {
                        pageId: "overview"; themeStore: win.themeStore
                        onNavigate: (id) => win.go(id)
                    }
                    Appearance { pageId: "appearance"; themeStore: win.themeStore }
                    TopBar { pageId: "topbar"; themeStore: win.themeStore }
                    Dock { pageId: "dock"; themeStore: win.themeStore }
                    Launcher { pageId: "launcher"; themeStore: win.themeStore }
                    Wallpaper { pageId: "wallpaper"; themeStore: win.themeStore }
                    About {
                        pageId: "about"; themeStore: win.themeStore
                        onRestoreDefaults: win.themeStore.resetPaths([])
                    }
                }
            }
        }
    }
}
