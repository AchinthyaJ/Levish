// Application launcher — Complete application menu for Levish.
// Features Grid and List views, category filtering, search with keyboard-first navigation,
// pinned applications section, and right-click pin/unpin persistence.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../common" as C
import "../common/Theme.js" as Theme
import "../common" as Pal

PanelWindow {
    id: win
    required property var dockState     // DockModel: desktop-entry list, pinning
    property bool open: false
    signal closeRequested()

    property var themeStore: null
    property string viewMode: themeStore ? themeStore.launcherDefaultView : "grid"    // "grid" or "list"
    property string activeCategory: "All"
    readonly property int iconPx: themeStore ? themeStore.launcherIconSize : 42
    readonly property int gridColumns: themeStore ? themeStore.launcherColumns : 5

    visible: open
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "#22000000"
    WlrLayershell.namespace: "levish-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onOpenChanged: {
        if (open) {
            search.text = ""
            activeCategory = "All"
            search.forceActiveFocus()
            enterAnim.restart()
        }
    }

    readonly property var categories: ["All", "Pinned", "Development", "Internet", "Multimedia", "Utilities", "System", "Games"]

    // Visible apps, sorted by name, filtered by category and query
    // Desktop IDs the user hid in Settings, normalised (no .desktop suffix, lower case).
    readonly property var hiddenIds: themeStore
        ? String(themeStore.launcherHidden).split(",").map(s => s.trim().replace(/\.desktop$/i, "").toLowerCase()).filter(s => s.length > 0)
        : []

    readonly property var results: {
        dockState.appsRevision
        const q = search.text.trim().toLowerCase()
        const cat = activeCategory
        const apps = dockState.listOf(DesktopEntries.applications)
        const out = []
        const hidden = win.hiddenIds

        for (const a of apps) {
            if (a.noDisplay) continue
            if (hidden.indexOf(String(a.id).toLowerCase()) >= 0) continue

            // Category filter
            if (cat === "Pinned") {
                if (!dockState.isPinned(a)) continue
            } else if (cat !== "All") {
                const cats = String(a.categories || "").toLowerCase()
                const hayCat = cat.toLowerCase()
                let match = false
                if (hayCat === "development" && (cats.includes("development") || cats.includes("ide") || cats.includes("programming"))) match = true
                else if (hayCat === "internet" && (cats.includes("network") || cats.includes("webbrowser") || cats.includes("chat") || cats.includes("email"))) match = true
                else if (hayCat === "multimedia" && (cats.includes("audio") || cats.includes("video") || cats.includes("graphics") || cats.includes("music"))) match = true
                else if (hayCat === "utilities" && (cats.includes("utility") || cats.includes("accessories") || cats.includes("tools"))) match = true
                else if (hayCat === "system" && (cats.includes("system") || cats.includes("settings") || cats.includes("terminal"))) match = true
                else if (hayCat === "games" && (cats.includes("game"))) match = true
                if (!match) continue
            }

            // Search query filter
            if (q.length > 0) {
                const hay = (a.name + " " + (a.genericName || "") + " " + (a.keywords || "") + " " + (a.id || "")).toLowerCase()
                if (hay.indexOf(q) < 0) continue
            }

            out.push(a)
        }

        if (win.themeStore && win.themeStore.launcherSort === "pinned_first") {
            out.sort((x, y) => (dockState.isPinned(x) ? 0 : 1) - (dockState.isPinned(y) ? 0 : 1) || x.name.localeCompare(y.name))
        } else {
            out.sort((x, y) => x.name.localeCompare(y.name))
        }
        return out.slice(0, 300)
    }

    function launch(entry) {
        if (!entry) return
        entry.execute()
        win.closeRequested()
    }

    // Dismiss when clicking outside panel
    MouseArea {
        anchors.fill: parent
        onClicked: win.closeRequested()
    }

    Rectangle {
        id: panel
        width: Math.min(840, Math.round(win.width * 0.42))
        height: Math.min(620, Math.round(win.height * 0.62))
        anchors.centerIn: parent
        radius: 24
        color: Pal.Palette.glass
        border.color: Pal.Palette.glassEdge
        border.width: 1

        opacity: 0
        scale: 0.95
        NumberAnimation {
            id: enterAnim
            target: panel
            properties: "opacity,scale"
            from: 0; to: 1
            duration: Theme.dur(200)
            easing.type: Easing.OutCubic
        }

        // Catch clicks within panel
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            // ── Top Header: Title, Category Pills, View Mode Switcher ──────
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: "APPLICATIONS"
                    color: Pal.Palette.accent
                    font.pixelSize: Theme.fs(11)
                    font.letterSpacing: 2
                    font.weight: Font.Bold
                }

                Item { Layout.fillWidth: true }

                // View Mode Toggle (Grid / List)
                Rectangle {
                    implicitWidth: 64; implicitHeight: 28
                    radius: 8
                    color: Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.094)
                    border.color: Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.133)
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 2

                        Rectangle {
                            width: 28; height: 22
                            radius: 6
                            color: win.viewMode === "grid" ? Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.2) : "transparent"
                            C.Icon {
                                anchors.centerIn: parent
                                width: 12; height: 12
                                kind: "grid"
                                tint: win.viewMode === "grid" ? Pal.Palette.accent : Pal.Palette.muted
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.viewMode = "grid"
                            }
                        }

                        Rectangle {
                            width: 28; height: 22
                            radius: 6
                            color: win.viewMode === "list" ? Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.2) : "transparent"
                            C.Icon {
                                anchors.centerIn: parent
                                width: 12; height: 12
                                kind: "list"
                                tint: win.viewMode === "list" ? Pal.Palette.accent : Pal.Palette.muted
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.viewMode = "list"
                            }
                        }
                    }
                }
            }

            // ── Search Input Box ──────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 42
                radius: 12
                color: Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.094)
                border.color: search.activeFocus ? Pal.Palette.accent : Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.133)
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: Theme.dur(150) } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    C.Icon {
                        width: 16; height: 16
                        kind: "search"
                        tint: search.activeFocus ? Pal.Palette.accent : Pal.Palette.muted
                    }

                    TextInput {
                        id: search
                        Layout.fillWidth: true
                        verticalAlignment: TextInput.AlignVCenter
                        color: Pal.Palette.text
                        font.pixelSize: Theme.fs(15)
                        font.weight: Font.Normal
                        clip: true
                        selectByMouse: true
                        focus: win.open

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            visible: search.text.length === 0
                            text: "Type to search applications…"
                            color: Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.333)
                            font.pixelSize: Theme.fs(15)
                        }

                        Keys.onEscapePressed: win.closeRequested()
                        Keys.onReturnPressed: {
                            if (win.viewMode === "grid") {
                                if (win.results.length > grid.currentIndex) win.launch(win.results[grid.currentIndex])
                            } else {
                                if (win.results.length > list.currentIndex) win.launch(win.results[list.currentIndex])
                            }
                        }
                        Keys.onEnterPressed: {
                            if (win.viewMode === "grid") {
                                if (win.results.length > grid.currentIndex) win.launch(win.results[grid.currentIndex])
                            } else {
                                if (win.results.length > list.currentIndex) win.launch(win.results[list.currentIndex])
                            }
                        }
                        Keys.onDownPressed: {
                            if (win.viewMode === "grid") grid.moveCurrentIndexDown()
                            else list.incrementCurrentIndex()
                        }
                        Keys.onUpPressed: {
                            if (win.viewMode === "grid") grid.moveCurrentIndexUp()
                            else list.decrementCurrentIndex()
                        }
                        Keys.onRightPressed: if (win.viewMode === "grid") grid.moveCurrentIndexRight()
                        Keys.onLeftPressed:  if (win.viewMode === "grid") grid.moveCurrentIndexLeft()
                    }

                    // Clear button
                    Rectangle {
                        visible: search.text.length > 0
                        implicitWidth: 20; implicitHeight: 20
                        radius: 10
                        color: clearMA.containsMouse ? Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.2) : Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.094)
                        C.Icon {
                            anchors.centerIn: parent
                            width: 10; height: 10
                            kind: "close"
                            tint: Pal.Palette.muted
                        }
                        MouseArea {
                            id: clearMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { search.text = ""; search.forceActiveFocus() }
                        }
                    }
                }
            }

            // ── Category Chips ────────────────────────────────────────────
            Row {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: win.categories
                    delegate: Rectangle {
                        required property string modelData
                        implicitWidth: catText.implicitWidth + 18
                        implicitHeight: 24
                        radius: 12
                        readonly property bool isActive: win.activeCategory === modelData
                        color: isActive ? Pal.Palette.accent : (catMA.containsMouse ? Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.133) : Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.071))
                        border.color: isActive ? Pal.Palette.accent : Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.094)
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: Theme.dur(140) } }

                        Text {
                            id: catText
                            anchors.centerIn: parent
                            text: modelData
                            color: isActive ? "#111827" : Pal.Palette.text
                            font.pixelSize: Theme.fs(11)
                            font.weight: isActive ? Font.DemiBold : Font.Normal
                        }

                        MouseArea {
                            id: catMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                win.activeCategory = modelData
                                grid.currentIndex = 0
                                list.currentIndex = 0
                            }
                        }
                    }
                }
            }

            // Divider line
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.094)
            }

            // ── App Views: GRID or LIST ────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // GRID VIEW
                GridView {
                    id: grid
                    anchors.fill: parent
                    visible: win.viewMode === "grid"
                    clip: true
                    cellWidth: Math.floor(width / win.gridColumns)
                    cellHeight: 96
                    model: win.results
                    boundsBehavior: Flickable.StopAtBounds
                    currentIndex: 0
                    onCountChanged: currentIndex = 0

                    delegate: Item {
                        required property var modelData
                        required property int index
                        width: grid.cellWidth
                        height: grid.cellHeight

                        readonly property bool selected: index === grid.currentIndex || cellMA.containsMouse

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: 14
                            color: selected ? Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.122) : "transparent"
                            border.color: selected ? Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.2) : "transparent"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: Theme.dur(140) } }

                            Image {
                                id: gridIco
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 10
                                width: win.iconPx; height: win.iconPx
                                source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                smooth: true
                                mipmap: true
                                scale: selected ? 1.08 : 1
                                Behavior on scale { NumberAnimation { duration: Theme.dur(160); easing.type: Easing.OutCubic } }
                            }

                            Text {
                                anchors { left: parent.left; right: parent.right; top: gridIco.bottom; topMargin: 6; leftMargin: 6; rightMargin: 6 }
                                text: modelData.name
                                color: selected ? "#ffffff" : Pal.Palette.text
                                font.pixelSize: Theme.fs(11)
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            // Pinned dot
                            Rectangle {
                                visible: win.dockState.isPinned(modelData)
                                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 5 }
                                width: 4; height: 4; radius: 2
                                color: Pal.Palette.accent
                            }
                        }

                        MouseArea {
                            id: cellMA
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onEntered: grid.currentIndex = index
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton) win.dockState.togglePin(modelData)
                                else win.launch(modelData)
                            }
                        }
                    }
                }

                // LIST VIEW
                ListView {
                    id: list
                    anchors.fill: parent
                    visible: win.viewMode === "list"
                    clip: true
                    spacing: 4
                    model: win.results
                    boundsBehavior: Flickable.StopAtBounds
                    currentIndex: 0
                    onCountChanged: currentIndex = 0

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: list.width
                        implicitHeight: 40
                        radius: 10

                        readonly property bool selected: index === list.currentIndex || listMA.containsMouse
                        color: selected ? Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.122) : "transparent"
                        border.color: selected ? Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.2) : "transparent"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: Theme.dur(140) } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 12
                            spacing: 12

                            Image {
                                Layout.preferredWidth: 26
                                Layout.preferredHeight: 26
                                source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                smooth: true
                            }

                            Text {
                                text: modelData.name
                                color: selected ? "#ffffff" : Pal.Palette.text
                                font.pixelSize: Theme.fs(13)
                                font.weight: Font.Medium
                            }

                            Text {
                                visible: (modelData.genericName || "").length > 0
                                text: "— " + (modelData.genericName || "")
                                color: Pal.Palette.muted
                                font.pixelSize: Theme.fs(11)
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Item { Layout.fillWidth: true; visible: !(modelData.genericName || "").length }

                            // Pinned badge in list
                            Rectangle {
                                visible: win.dockState.isPinned(modelData)
                                implicitWidth: 48; implicitHeight: 18
                                radius: 4
                                color: Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.133)
                                Text {
                                    anchors.centerIn: parent
                                    text: "PINNED"
                                    color: Pal.Palette.accent
                                    font.pixelSize: Theme.fs(8)
                                    font.weight: Font.Bold
                                }
                            }
                        }

                        MouseArea {
                            id: listMA
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onEntered: list.currentIndex = index
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton) win.dockState.togglePin(modelData)
                                else win.launch(modelData)
                            }
                        }
                    }
                }
            }

            // ── Footer Hint ───────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: win.results.length + " applications found"
                    color: Pal.Palette.muted
                    font.pixelSize: Theme.fs(10)
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "Enter: Launch  ·  Right-Click: Pin/Unpin  ·  Esc: Close"
                    color: Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.333)
                    font.pixelSize: Theme.fs(10)
                }
            }
        }
    }
}
