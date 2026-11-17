import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../components"
import "../../common" as C
import "../../common/Theme.js" as Theme
import "../../wallpaper/WallpaperPaths.js" as Paths
import "../../common" as Pal

// Wallpaper manager: Pick and manage desktop wallpapers for Hyprland and Levish.
// Features multi-source discovery, live preview banner, instant fit modes,
// auto-rotation slideshow controls, custom directory scanning, and reactive gallery grid.
Flickable {
    id: page
    property var themeStore
    property string pageId: "wallpaper"
    ScrollBar.vertical: PageScrollBar { accent: page.accent }
    property string keywords: "wallpaper background image picture desktop hyprpaper rotate slideshow"
    // Per-monitor overrides, stored as "NAME=/path;NAME=/path" in wallpaper.monitors.
    function overrideFor(name) {
        const list = Paths.parseMonitors(page.themeStore.wallpaperMonitors)
        for (const e of list) if (e.monitor === name) return e.path
        return ""
    }
    function setOverride(name, value) {
        const kept = Paths.parseMonitors(page.themeStore.wallpaperMonitors).filter(e => e.monitor !== name)
        const v = String(value || "").trim()
        if (v.length) kept.push({ monitor: name, path: v })
        page.themeStore.set("wallpaper.monitors", kept.map(e => e.monitor + "=" + e.path).join(";"))
    }
    readonly property var resetPaths: ["wallpaper.path", "wallpaper.folder", "wallpaper.fit", "wallpaper.auto_rotate", "wallpaper.interval", "wallpaper.monitors"]
    readonly property color accent: themeStore ? themeStore.accentColor : Pal.Palette.accent

    readonly property string activePath: (themeStore && themeStore.wallpaperPath && themeStore.wallpaperPath !== "")
                                        ? themeStore.wallpaperPath
                                        : "/usr/share/hypr/wall0.png"
    readonly property string activeFit: (themeStore && themeStore.wallpaperFit) ? themeStore.wallpaperFit : "cover"
    readonly property bool autoRotate: themeStore ? themeStore.wallpaperAutoRotate : false
    readonly property int rotateInterval: themeStore ? themeStore.wallpaperInterval : 1800
    readonly property string customFolder: (themeStore && themeStore.wallpaperFolder) ? themeStore.wallpaperFolder.trim() : ""

    property var allWallpapers: []
    property string selectedCategory: "all"  // "all" | "hyprland" | "pictures" | "system" | "custom"
    property string searchQuery: ""

    function rescan() {
        scanner.command = Paths.scanCommand(Paths.scanRoots(Quickshell.env("HOME") || "",
                                                             Quickshell.env("XDG_PICTURES_DIR") || "",
                                                             page.customFolder))
        scanner.running = true
    }

    function randomize() {
        if (page.filteredWallpapers.length > 0) {
            const idx = Math.floor(Math.random() * page.filteredWallpapers.length)
            page.setWallpaper(page.filteredWallpapers[idx])
        } else if (page.allWallpapers.length > 0) {
            const idx = Math.floor(Math.random() * page.allWallpapers.length)
            page.setWallpaper(page.allWallpapers[idx])
        }
    }

    function setWallpaper(filePath) {
        if (page.themeStore) {
            page.themeStore.set("wallpaper.path", filePath)
        }
    }

    Component.onCompleted: rescan()
    onCustomFolderChanged: rescan()

    Process {
        id: scanner
        stdout: StdioCollector {
            onStreamFinished: {
                const list = this.text.trim().split("\n").filter(p => p.length > 0)
                page.allWallpapers = list
                if (page.themeStore && page.themeStore.setWallpaperList) {
                    page.themeStore.setWallpaperList(list)
                }
            }
        }
    }

    // Filter wallpapers based on selected category and search query
    readonly property var filteredWallpapers: {
        const q = searchQuery.trim().toLowerCase()
        const cat = selectedCategory

        return allWallpapers.filter(item => {
            // Category check
            if (cat === "hyprland" && !item.startsWith("/usr/share/hypr")) return false
            if (cat === "pictures" && item.indexOf("/Pictures") < 0) return false
            if (cat === "system" && !item.startsWith("/usr/share/backgrounds") && !item.startsWith("/usr/share/wallpapers")) return false
            if (cat === "custom") {
                if (page.customFolder === "" || !item.startsWith(page.customFolder)) return false
            }

            // Search query check
            if (q !== "") {
                const name = item.split("/").pop().toLowerCase()
                if (name.indexOf(q) < 0) return false
            }
            return true
        })
    }

    contentHeight: mainCol.implicitHeight + 48
    clip: true

    ColumnLayout {
        id: mainCol
        x: 24; y: 20
        width: page.width - 48
        spacing: 16

        // =====================================================================
        // ACTIVE WALLPAPER HERO BANNER
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 130
            radius: 14
            color: Pal.Palette.surface
            border.color: Qt.rgba(page.accent.r, page.accent.g, page.accent.b, 0.3)
            border.width: 1

            RowLayout {
                anchors { fill: parent; margins: 12 }
                spacing: 16

                // Active Wallpaper Thumbnail Frame
                Rectangle {
                    Layout.preferredWidth: 168
                    Layout.fillHeight: true
                    radius: 10
                    color: Pal.Palette.sidebar
                    border.color: Pal.Palette.surfaceEdge
                    border.width: 1
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: "file://" + encodeURI(page.activePath)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 336
                        sourceSize.height: 210
                    }

                    // Mode Badge on Thumbnail
                    Rectangle {
                        anchors { left: parent.left; top: parent.top; margins: 6 }
                        height: 18
                        width: badgeText.implicitWidth + 12
                        radius: 5
                        color: Pal.Palette.window
                        border.color: page.accent
                        border.width: 1

                        Text {
                            id: badgeText
                            anchors.centerIn: parent
                            text: page.activeFit.toUpperCase()
                            color: page.accent
                            font.pixelSize: Theme.fs(9)
                            font.weight: Font.Bold
                        }
                    }
                }

                // Active Details & Control Buttons
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: "ACTIVE WALLPAPER"
                            color: page.accent
                            font.pixelSize: Theme.fs(11)
                            font.weight: Font.Bold
                            font.letterSpacing: 0.5
                        }
                        Rectangle {
                            width: 6; height: 6; radius: 3
                            color: Pal.Palette.ok
                        }
                        Text {
                            text: "Live on Hyprland"
                            color: Pal.Palette.muted
                            font.pixelSize: Theme.fs(11)
                        }
                        Item { Layout.fillWidth: true }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: page.activePath.split("/").pop()
                        color: Pal.Palette.textPrimary
                        font.pixelSize: Theme.fs(16)
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: page.activePath
                        color: Pal.Palette.muted
                        font.pixelSize: Theme.fs(11)
                        elide: Text.ElideMiddle
                    }

                    Item { Layout.fillHeight: true }

                    // Action buttons: Shuffle, Rescan, Reset
                    RowLayout {
                        spacing: 8
                        Layout.topMargin: 4

                        // Randomize / Shuffle Button
                        Rectangle {
                            height: 28
                            implicitWidth: rndRow.implicitWidth + 18
                            radius: 7
                            color: rndMa.containsMouse ? Qt.rgba(page.accent.r, page.accent.g, page.accent.b, 0.28) : Qt.rgba(page.accent.r, page.accent.g, page.accent.b, 0.15)
                            border.color: page.accent
                            border.width: 1

                            Row {
                                id: rndRow
                                anchors.centerIn: parent
                                spacing: 6
                                C.Icon {
                                    kind: "shuffle"
                                    width: 13; height: 13
                                    tint: page.accent
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: "Randomize"
                                    color: page.accent
                                    font.pixelSize: Theme.fs(11)
                                    font.weight: Font.DemiBold
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            MouseArea {
                                id: rndMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.randomize()
                            }
                        }

                        // Rescan / Refresh Button
                        Rectangle {
                            height: 28
                            implicitWidth: refRow.implicitWidth + 18
                            radius: 7
                            color: refMa.containsMouse ? Pal.Palette.surfaceHover : Pal.Palette.controlFill
                            border.color: Pal.Palette.controlEdge
                            border.width: 1

                            Row {
                                id: refRow
                                anchors.centerIn: parent
                                spacing: 6
                                C.Icon {
                                    kind: "refresh"
                                    width: 13; height: 13
                                    tint: Pal.Palette.textPrimary
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: "Rescan"
                                    color: Pal.Palette.textPrimary
                                    font.pixelSize: Theme.fs(11)
                                    font.weight: Font.Medium
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            MouseArea {
                                id: refMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.rescan()
                            }
                        }

                        // Reset to Default Button
                        SettingsButton {
                            text: "Default"
                            onClicked: page.setWallpaper("/usr/share/hypr/wall0.png")
                        }
                    }
                }
            }
        }

        // =====================================================================
        // DISPLAY FIT MODE & SLIDESHOW OPTIONS
        // =====================================================================
        SettingsCard {
            title: "Per-monitor wallpapers"
            SettingsRow {
                label: "Screens"
                hint: "Give a screen its own image. Leave a field empty to use the general wallpaper."
            }
            Repeater {
                model: Quickshell.screens
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 40
                    radius: 9
                    color: Pal.Palette.controlFill
                    border.color: monField.activeFocus ? page.accent : Pal.Palette.controlEdge
                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 8 }
                        spacing: 10
                        Text {
                            text: modelData.name
                            color: Pal.Palette.textSecondary
                            font.pixelSize: Theme.fs(12)
                            font.weight: Font.DemiBold
                            Layout.preferredWidth: 110
                        }
                        TextField {
                            id: monField
                            Layout.fillWidth: true
                            text: page.overrideFor(modelData.name)
                            placeholderText: "General wallpaper"
                            placeholderTextColor: Pal.Palette.muted
                            color: Pal.Palette.text
                            font.pixelSize: Theme.fs(12)
                            background: Item {}
                            onEditingFinished: page.setOverride(modelData.name, text)
                        }
                    }
                }
            }
        }

        SettingsCard {
            title: "Display & Slideshow"

            SettingsRow {
                label: "Scaling & Fit Mode"
                hint: "Controls how wallpapers are scaled to fit your screen."
                SettingsChoice {
                    accent: page.accent
                    current: page.activeFit
                    options: [
                        { value: "cover",   label: "Cover (Fill & Crop)" },
                        { value: "contain", label: "Contain (Fit Aspect)" },
                        { value: "stretch", label: "Stretch (Fill Exact)" },
                        { value: "tile",    label: "Tile (Pattern)" }
                    ]
                    onPicked: (val) => {
                        if (page.themeStore) page.themeStore.set("wallpaper.fit", val)
                    }
                }
            }

            SettingsRow {
                label: "Auto-Rotate Wallpaper"
                hint: page.autoRotate ? ("Cycling through wallpapers every " + Math.round(page.rotateInterval / 60) + " minutes.")
                                     : "Automatically cycle through your wallpapers at a set interval."
                SettingsToggle {
                    checked: page.autoRotate
                    accent: page.accent
                    onToggled: (v) => {
                        if (page.themeStore) page.themeStore.set("wallpaper.auto_rotate", v)
                    }
                }
            }

            SettingsRow {
                visible: page.autoRotate
                label: "Rotation Interval"
                hint: "How frequently to switch to the next wallpaper."
                SettingsChoice {
                    accent: page.accent
                    current: page.rotateInterval
                    options: [
                        { value: 60,   label: "1 min" },
                        { value: 300,  label: "5 min" },
                        { value: 900,  label: "15 min" },
                        { value: 1800, label: "30 min" },
                        { value: 3600, label: "1 hr" },
                        { value: 7200, label: "2 hrs" }
                    ]
                    onPicked: (val) => {
                        if (page.themeStore) page.themeStore.set("wallpaper.interval", val)
                    }
                }
            }
        }

        // =====================================================================
        // DIRECTORY & SOURCE SELECTION
        // =====================================================================
        SettingsCard {
            title: "Wallpaper Sources & Folders"

            SettingsRow {
                label: "Custom Wallpaper Directory"
                hint: page.customFolder !== "" ? page.customFolder : "No custom folder set. Using system & home directories."

                Flow {
                    width: parent.width
                    spacing: 8

                    TextField {
                        id: folderField
                        width: Math.min(240, parent.width); height: 30
                        text: page.customFolder
                        placeholderText: Quickshell.env("HOME") + "/Pictures/Wallpapers"
                        placeholderTextColor: Pal.Palette.muted
                        font.pixelSize: Theme.fs(12)
                        color: Pal.Palette.textPrimary
                        background: Rectangle {
                            radius: 8
                            color: Pal.Palette.controlFill
                            border.color: folderField.activeFocus ? page.accent : Pal.Palette.controlEdge
                        }
                        onEditingFinished: {
                            if (page.themeStore) page.themeStore.set("wallpaper.folder", text.trim())
                        }
                    }

                    SettingsButton {
                        text: "Apply"
                        onClicked: {
                            if (page.themeStore) page.themeStore.set("wallpaper.folder", folderField.text.trim())
                        }
                    }

                    SettingsButton {
                        visible: page.customFolder !== ""
                        text: "Clear"
                        danger: true
                        onClicked: {
                            folderField.text = ""
                            if (page.themeStore) page.themeStore.set("wallpaper.folder", "")
                        }
                    }
                }
            }

            // Quick Folder Presets
            SettingsRow {
                label: "Quick Folder Presets"
                hint: "Click a path to load wallpapers from that folder."
                Row {
                    spacing: 6
                    Repeater {
                        model: [
                            { label: "Hyprland", path: "/usr/share/hypr" },
                            { label: "Pictures", path: Quickshell.env("HOME") + "/Pictures" },
                            { label: "System", path: "/usr/share/backgrounds" }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            height: 26
                            width: chipText.implicitWidth + 18
                            radius: 6
                            color: chipMa.containsMouse ? Pal.Palette.surfaceHover : Pal.Palette.controlFill
                            border.color: page.customFolder === modelData.path ? page.accent : Pal.Palette.controlEdge
                            border.width: 1

                            Text {
                                id: chipText
                                anchors.centerIn: parent
                                text: modelData.label
                                color: page.customFolder === modelData.path ? page.accent : Pal.Palette.text
                                font.pixelSize: Theme.fs(11)
                            }
                            MouseArea {
                                id: chipMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    folderField.text = modelData.path
                                    if (page.themeStore) page.themeStore.set("wallpaper.folder", modelData.path)
                                }
                            }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // WALLPAPER GALLERY & CATEGORY FILTERING
        // =====================================================================
        SettingsCard {
            title: "Wallpaper Gallery (" + page.filteredWallpapers.length + " wallpapers)"

            // Filter Chips & Search Bar Row. A Flow, so the search box wraps under the chips
            // instead of pushing the page wider than the window at narrow widths.
            Flow {
                Layout.fillWidth: true
                spacing: 12

                // Category Chips
                Row {
                    spacing: 6
                    Repeater {
                        model: [
                            { id: "all",      label: "All" },
                            { id: "hyprland", label: "Hyprland" },
                            { id: "pictures", label: "Pictures" },
                            { id: "system",   label: "System" },
                            { id: "custom",   label: "Custom" }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool selected: page.selectedCategory === modelData.id
                            height: 28
                            width: catLabel.implicitWidth + 20
                            radius: 8
                            color: selected ? Qt.rgba(page.accent.r, page.accent.g, page.accent.b, 0.22) : (catMa.containsMouse ? Pal.Palette.surfaceHover : Pal.Palette.controlFill)
                            border.color: selected ? page.accent : Pal.Palette.controlEdge
                            border.width: 1

                            Text {
                                id: catLabel
                                anchors.centerIn: parent
                                text: modelData.label
                                color: selected ? Pal.Palette.text : Pal.Palette.muted
                                font.pixelSize: Theme.fs(11)
                                font.weight: selected ? Font.DemiBold : Font.Normal
                            }
                            MouseArea {
                                id: catMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.selectedCategory = modelData.id
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Search Filter Box
                Rectangle {
                    width: 200; height: 30; radius: 8
                    color: Pal.Palette.controlFill
                    border.color: searchField.activeFocus ? page.accent : Pal.Palette.controlEdge

                    RowLayout {
                        anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                        spacing: 6
                        C.Icon {
                            kind: "search"
                            width: 13; height: 13
                            tint: searchField.text.length > 0 ? page.accent : Pal.Palette.muted
                        }
                        TextField {
                            id: searchField
                            Layout.fillWidth: true
                            placeholderText: "Search..."
                            placeholderTextColor: Pal.Palette.muted
                            color: Pal.Palette.textPrimary
                            font.pixelSize: Theme.fs(11)
                            background: Item {}
                            text: page.searchQuery
                            onTextChanged: page.searchQuery = text
                        }
                        C.Icon {
                            visible: searchField.text.length > 0
                            kind: "close"
                            width: 12; height: 12
                            tint: Pal.Palette.muted
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: searchField.text = ""
                            }
                        }
                    }
                }
            }

            // Thumbnail Grid
            Flow {
                Layout.fillWidth: true
                spacing: 12

                Repeater {
                    model: page.filteredWallpapers
                    delegate: Rectangle {
                        id: card
                        required property string modelData
                        readonly property bool chosen: page.activePath === modelData
                        width: 182; height: 114
                        radius: 10
                        color: Pal.Palette.surface
                        border.width: chosen ? 2 : 1
                        border.color: chosen ? page.accent : (cardMa.containsMouse ? Pal.Palette.surfaceHover : Pal.Palette.controlEdge)
                        clip: true

                        Behavior on border.color { ColorAnimation { duration: Theme.dur(150) } }
                        Behavior on scale { NumberAnimation { duration: Theme.dur(120) } }
                        scale: cardMa.containsMouse ? 1.02 : 1.0

                        // Wallpaper Image
                        Image {
                            anchors.fill: parent
                            anchors.margins: card.chosen ? 2 : 1
                            source: "file://" + encodeURI(modelData)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            smooth: true
                            sourceSize.width: 364
                            sourceSize.height: 228
                        }

                        // Bottom Scrim Overlay for Readable Title
                        Rectangle {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                            height: 32
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 1.0; color: Pal.Palette.window }
                            }
                        }

                        // Filename Label
                        Text {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                                margins: 6
                            }
                            text: modelData.split("/").pop()
                            color: card.chosen ? page.accent : Pal.Palette.textPrimary
                            font.pixelSize: Theme.fs(10)
                            font.weight: card.chosen ? Font.DemiBold : Font.Normal
                            elide: Text.ElideMiddle
                        }

                        // Selected Checkmark Badge (Top Right)
                        Rectangle {
                            visible: card.chosen
                            anchors { right: parent.right; top: parent.top; margins: 6 }
                            width: 20; height: 20; radius: 10
                            color: page.accent

                            C.Icon {
                                anchors.centerIn: parent
                                width: 12; height: 12
                                kind: "check"
                                tint: Pal.Palette.sidebar
                            }
                        }

                        MouseArea {
                            id: cardMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: page.setWallpaper(modelData)
                        }
                    }
                }
            }

            // Empty State Notice
            Item {
                visible: page.filteredWallpapers.length === 0
                Layout.fillWidth: true
                implicitHeight: 120

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    C.Icon {
                        Layout.alignment: Qt.AlignHCenter
                        kind: "image"
                        width: 28; height: 28
                        tint: Pal.Palette.muted
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "No wallpapers found matching this filter."
                        color: Pal.Palette.muted
                        font.pixelSize: Theme.fs(13)
                    }
                    SettingsButton {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Reset Filter to All"
                        onClicked: {
                            page.selectedCategory = "all"
                            page.searchQuery = ""
                        }
                    }
                }
            }
        }
    }
}
