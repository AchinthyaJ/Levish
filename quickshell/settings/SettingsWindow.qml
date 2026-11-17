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
import "../common" as Pal

FloatingWindow {
    id: win
    required property var themeStore
    property var notifications: null     // NotificationService, owned by shell.qml
    property var clipboard: null         // ClipboardService, owned by shell.qml
    property var hypr: null              // HyprQuery (read-only Hyprland queries), owned by shell.qml
    property var session: null           // SessionTools (night light, caffeine), owned by shell.qml
    property var lock: null              // LockService (lock screen and idle), owned by shell.qml
    property bool open: false
    signal closeRequested()

    // Never shown at startup: the window only appears when `open` is set.
    visible: false

    title: "Levish Settings"
    implicitWidth: 980
    implicitHeight: 660
    minimumSize: Qt.size(640, 520)
    color: Pal.Palette.window

    // Below this width the sidebar collapses to an icon rail, so pages keep room for their controls.
    readonly property bool compact: width < 820
    readonly property int sidebarWidth: compact ? 68 : 232

    // The window is shown when `open` is set. Closing it from the compositor clears `open`.
    onOpenChanged: visible = open
    onVisibleChanged: if (!visible && win.open) win.closeRequested()

    readonly property color accent: themeStore.accentColor
    // Opens on the page used last time. Follows the saved value once the config has loaded.
    property string currentId: themeStore.settingsLastPage
    property string query: ""
    property var audio: null          // AudioService, from shell.qml

    readonly property var pageList: [
        { id: "overview",   title: "Overview",               icon: "grid" },
        { id: "appearance", title: "Appearance",             icon: "sun" },
        { id: "topbar",     title: "Top Bar",                icon: "up" },
        { id: "dock",       title: "Dock",                   icon: "down" },
        { id: "launcher",   title: "Application Launcher",   icon: "apps" },
        { id: "wallpaper",  title: "Wallpaper",              icon: "image" },
        { id: "notifications", title: "Notifications",       icon: "note" },
        { id: "osd",        title: "On-Screen Display",      icon: "sun" },
        { id: "clipboard",  title: "Clipboard",              icon: "note" },
        { id: "keyboard",   title: "Keyboard & Shortcuts",   icon: "gear" },
        { id: "displays",   title: "Displays",               icon: "grid" },
        { id: "sound",      title: "Sound",                  icon: "sun" },
        { id: "network",    title: "Network",                icon: "grid" },
        { id: "bluetooth",  title: "Bluetooth",              icon: "grid" },
        { id: "session",    title: "Night Light & Caffeine", icon: "moon" },
        { id: "lock",       title: "Lock & Idle",            icon: "lock" },
        { id: "about",      title: "About Levish",           icon: "note" }
    ]

    function pageItem(id) {
        for (let i = 0; i < pageStack.children.length; i++) if (pageStack.children[i].pageId === id) return pageStack.children[i]
        return null
    }
    readonly property var currentPage: pageItem(currentId)

    // Matches on page title and the keywords each page declares.
    // ── Search ─────────────────────────────────────────────────────────
    // Every SettingsRow on every page is indexed by its label and hint, so search reaches individual
    // settings, not just pages. Rows are read from the live page tree, so the index always matches
    // what is on screen. Labels that are config keys (for example recent changes) are skipped.
    function _collectRows(item, pageId, pageTitle, pageIcon, out) {
        const kids = item.children
        for (let i = 0; i < kids.length; i++) {
            const c = kids[i]
            if (typeof c.label === "string" && c.label !== "" && ("hint" in c) && !/^[a-z_]+\./.test(c.label))
                out.push({ id: pageId, title: c.label, hint: c.hint || "", page: pageTitle, icon: pageIcon, isSetting: true, ref: c })
            _collectRows(c, pageId, pageTitle, pageIcon, out)
        }
        return out
    }

    readonly property var settingsIndex: {
        if (query.trim() === "") return []
        const out = []
        for (let i = 0; i < pageList.length; i++) {
            const p = pageList[i]
            const pg = pageItem(p.id)
            if (pg) _collectRows(pg, p.id, p.title, p.icon, out)
        }
        return out
    }

    // Pages first, then individual settings. A setting matches on its label, hint or page name.
    readonly property var results: {
        const q = query.trim().toLowerCase()
        if (q === "") return []
        const pages = pageList.filter(p => {
            const pg = pageItem(p.id)
            const hay = (p.title + " " + (pg ? pg.keywords : "")).toLowerCase()
            return hay.indexOf(q) >= 0
        }).map(p => ({ id: p.id, title: p.title, icon: p.icon, isSetting: false }))
        const settings = settingsIndex.filter(s => {
            const hay = (s.title + " " + s.hint + " " + s.page).toLowerCase()
            return hay.indexOf(q) >= 0
        })
        return pages.concat(settings)
    }

    // ── Keyboard navigation ────────────────────────────────────────────
    // Up/Down move through the sidebar (or the search results), Enter opens the highlighted entry,
    // Escape clears the search or closes the window.
    property int navIndex: 0
    readonly property var navItems: query.trim() !== "" ? results : pageList
    onQueryChanged: navIndex = 0

    function moveNav(step) {
        const n = navItems.length
        if (n === 0) return
        navIndex = (navIndex + step + n) % n
    }

    function openNav() {
        const item = navItems[navIndex]
        if (item) openEntry(item)
    }

    // Opens a page, or a single setting: the page opens and the setting row is scrolled into view.
    property var pendingRow: null
    property string pendingPage: ""
    function openEntry(entry) {
        query = ""
        if (entry.isSetting) {
            pendingRow = entry.ref
            pendingPage = entry.id
            rememberPage(entry.id)
            Qt.callLater(win.scrollToPending)
        } else {
            rememberPage(entry.id)
        }
    }

    function scrollToPending() {
        if (!pendingRow) return
        const pg = pageItem(pendingPage)
        if (pg && pg.contentItem) {
            const p = pendingRow.mapToItem(pg.contentItem, 0, 0)
            pg.contentY = Math.max(0, p.y - 24)
        }
        pendingRow = null
    }

    function go(id) { rememberPage(id); query = "" }

    // Shows a page and saves it as the one to open next time (no write when it is unchanged).
    function rememberPage(id) {
        currentId = id
        if (themeStore.settingsLastPage !== id) themeStore.set("settings.last_page", id)
    }

    Rectangle {
        anchors.fill: parent
        color: Pal.Palette.window
        focus: win.open
        Keys.onEscapePressed: win.closeRequested()
        Keys.onUpPressed: win.moveNav(-1)
        Keys.onDownPressed: win.moveNav(1)
        Keys.onReturnPressed: win.openNav()
        Keys.onEnterPressed: win.openNav()

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ── Sidebar ────────────────────────────────────────────────
            Rectangle {
                Layout.preferredWidth: win.sidebarWidth
                Layout.fillHeight: true
                color: Pal.Palette.sidebar

                Rectangle { anchors { right: parent.right; top: parent.top; bottom: parent.bottom } width: 1; color: Pal.Palette.surfaceEdge }

                ColumnLayout {
                    anchors { fill: parent; margins: win.compact ? 10 : 16 }
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 10
                        spacing: 10
                        Rectangle {
                            width: 34; height: 34; radius: 11
                            color: Pal.Palette.iconTile
                            border.color: win.accent; border.width: 1
                            C.Icon { anchors.centerIn: parent; width: 18; height: 18; kind: "gear"; tint: win.accent }
                        }
                        ColumnLayout {
                            spacing: 0
                            visible: !win.compact
                            Text { text: "Settings"; color: Pal.Palette.text; font.pixelSize: Theme.fs(15); font.weight: Font.Bold }
                            Text { text: "Levish"; color: Pal.Palette.muted; font.pixelSize: Theme.fs(10) }
                        }
                    }

                    // Search across pages and their settings.
                    Rectangle {
                        Layout.fillWidth: true
                        visible: !win.compact
                        height: 32; radius: 9
                        color: Pal.Palette.controlFill
                        border.color: search.activeFocus ? win.accent : Pal.Palette.controlEdge
                        TextField {
                            id: search
                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            placeholderText: "Search settings"
                            placeholderTextColor: Pal.Palette.muted
                            color: Pal.Palette.text
                            font.pixelSize: Theme.fs(12)
                            background: Item {}
                            text: win.query
                            onTextChanged: win.query = text
                            Keys.onEscapePressed: { if (text !== "") text = ""; else win.closeRequested() }
                            // Enter opens the highlighted result. Handled here and stopped, so it never fires twice.
                            Keys.onReturnPressed: (event) => { win.openNav(); event.accepted = true }
                            Keys.onEnterPressed: (event) => { win.openNav(); event.accepted = true }
                            // Enter opens the first result, so search works from the keyboard alone.
                        }
                    }

                    Flickable {
                        id: navFlick
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        contentWidth: width
                        contentHeight: navCol.implicitHeight
                        ScrollBar.vertical: PageScrollBar { accent: win.accent }

                        // Keeps the Up/Down keyboard focus in view while the list scrolls.
                        // Entries are 36 px tall with 6 px between them.
                        Connections {
                            target: win
                            function onNavIndexChanged() {
                                const top = win.navIndex * 42
                                const bottom = top + 36
                                if (top < navFlick.contentY) navFlick.contentY = top
                                else if (bottom > navFlick.contentY + navFlick.height) navFlick.contentY = bottom - navFlick.height
                            }
                        }

                        ColumnLayout {
                            id: navCol
                            width: navFlick.width
                            spacing: 6

                        Repeater {
                            model: win.navItems
                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                implicitHeight: 36; radius: 9
                                readonly property bool selected: win.query.trim() === "" && win.currentId === modelData.id
                                // Keyboard focus ring: the entry Up/Down has reached.
                                readonly property bool keyFocus: index === win.navIndex
                                color: selected ? Qt.rgba(win.accent.r, win.accent.g, win.accent.b, 0.16)
                                     : (keyFocus || navMa.containsMouse ? Pal.Palette.controlFill : "transparent")
                                border.width: keyFocus && !selected ? 1 : 0
                                border.color: win.accent
                                Rectangle {
                                    visible: parent.selected
                                    width: 3; height: 18; radius: 2
                                    color: win.accent
                                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                                }
                                RowLayout {
                                    anchors { fill: parent; leftMargin: 12; rightMargin: 10 }
                                    spacing: 10
                                    C.Icon { width: 16; height: 16; kind: modelData.icon; tint: selected ? win.accent : Pal.Palette.muted }
                                    Text {
                                        Layout.fillWidth: true
                                        visible: !win.compact
                                        text: modelData.isSetting ? modelData.title + "  ·  " + modelData.page : modelData.title
                                        color: selected ? Pal.Palette.text : Pal.Palette.muted
                                        font.pixelSize: Theme.fs(13)
                                        font.weight: selected ? Font.DemiBold : Font.Normal
                                        elide: Text.ElideRight
                                    }
                                }
                                MouseArea {
                                    id: navMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: win.openEntry(modelData)
                                    ToolTip.visible: containsMouse && win.compact
                                    ToolTip.text: modelData.title
                                    ToolTip.delay: 400
                                }
                            }
                        }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: win.themeStore.status === "ok" ? "Saved to config/config.json"
                            : (win.themeStore.status === "missing" ? "No config file yet" : "Config needs attention")
                        color: win.themeStore.status === "ok" ? Pal.Palette.muted : Pal.Palette.danger
                        font.pixelSize: Theme.fs(10)
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
                        // Breadcrumb: the app name in muted text, then the page.
                        textFormat: Text.RichText
                        text: "<span style='color:" + Pal.Palette.muted + ";font-weight:normal'>Settings  ›  </span>"
                              + win.pageList.filter(p => p.id === win.currentId)[0].title
                        color: Pal.Palette.text
                        font.pixelSize: Theme.fs(18)
                        font.weight: Font.DemiBold
                    }
                    SettingsButton {
                        visible: win.currentPage && win.currentPage.resetPaths.length > 0
                        text: "Reset this page"
                        onClicked: win.themeStore.resetPaths(win.currentPage.resetPaths)
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Pal.Palette.surfaceEdge }

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
                    Notifications {
                        pageId: "notifications"; themeStore: win.themeStore
                        notifications: win.notifications
                    }
                    OsdSettings { pageId: "osd"; themeStore: win.themeStore }
                    Clipboard { pageId: "clipboard"; themeStore: win.themeStore; clipboard: win.clipboard }
                    Keyboard { pageId: "keyboard"; themeStore: win.themeStore; hypr: win.hypr }
                    Displays { pageId: "displays"; themeStore: win.themeStore; hypr: win.hypr }
                    Sound { pageId: "sound"; themeStore: win.themeStore; audio: win.audio }
                    Network { pageId: "network"; themeStore: win.themeStore }
                    Bluetooth { pageId: "bluetooth"; themeStore: win.themeStore }
                    Session { pageId: "session"; themeStore: win.themeStore; session: win.session }
                    Lock { pageId: "lock"; themeStore: win.themeStore; lock: win.lock }
                    About {
                        pageId: "about"; themeStore: win.themeStore
                        onRestoreDefaults: win.themeStore.resetPaths([])
                    }
                }
            }
        }
    }
}
