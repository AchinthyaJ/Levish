import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import "../../common/Theme.js" as Theme
import "../../common/Version.js" as Version
import "../components"
import "../../common" as Pal

// Overview dashboard: a visual summary of the live desktop. Every value comes from the config
// service or a real runtime check. Nothing is invented.
Flickable {
    id: page
    property var themeStore
    property string pageId: ""
    ScrollBar.vertical: PageScrollBar { accent: page.themeStore.accentColor }
    property string keywords: "overview summary status health configuration dashboard recent changes"
    readonly property var resetPaths: []
    readonly property color accent: themeStore.accentColor
    signal navigate(string pageId)

    // Runtime check: the Python backend writes its pid file on start and removes it on exit.
    property bool backendRunning: false
    FileView {
        id: backendPid
        path: "/tmp/levish/levish.pid"
        printErrors: false
        onLoaded: page.backendRunning = true
        onLoadFailed: page.backendRunning = false
    }

    contentHeight: col.implicitHeight + 40
    clip: true

    component Tile: Rectangle {
        property string caption: ""
        property string value: ""
        property string detail: ""
        property color valueColor: Pal.Palette.textPrimary
        width: 200
        implicitHeight: tileCol.implicitHeight + 28
        radius: Theme.radiusCardSet
        color: Pal.Palette.surface
        border.color: Pal.Palette.surfaceEdge
        border.width: 1
        ColumnLayout {
            id: tileCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
            spacing: 4
            Text { text: caption.toUpperCase(); color: Pal.Palette.muted; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold; font.letterSpacing: 1.1 }
            Text { Layout.fillWidth: true; text: value; color: valueColor; font.pixelSize: Theme.fontTitle; font.weight: Font.DemiBold; elide: Text.ElideRight }
            Text { Layout.fillWidth: true; text: detail; color: Pal.Palette.textSecondary; font.pixelSize: Theme.fontSmall; wrapMode: Text.Wrap }
        }
    }

    ColumnLayout {
        id: col
        x: Theme.space5; y: Theme.space4
        width: page.width - Theme.space5 * 2
        spacing: Theme.space3

        // ── Hero ────────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space3
            Rectangle {
                width: 44; height: 44; radius: 22
                color: page.accent
                Layout.alignment: Qt.AlignVCenter
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { text: "Desktop configuration"; color: Pal.Palette.textPrimary; font.pixelSize: Theme.fontPage; font.weight: Font.DemiBold }
                Text {
                    text: "Accent " + page.themeStore.accentColor.toUpperCase()
                        + "  ·  glass " + Math.round(page.themeStore.glassOpacity * 100) + "%"
                        + "  ·  " + page.themeStore.fontFamily
                    color: Pal.Palette.muted; font.pixelSize: Theme.fontSmall
                }
            }
        }

        // ── Status banner (only when the config needs attention) ──────────
        Rectangle {
            visible: page.themeStore.status !== "ok"
            Layout.fillWidth: true
            implicitHeight: banner.implicitHeight + 20
            radius: Theme.radiusRow
            color: Theme.dangerSoft
            border.color: Theme.dangerEdge
            Text {
                id: banner
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 12 }
                text: page.themeStore.statusDetail
                color: Pal.Palette.textPrimary
                font.pixelSize: Theme.fontSmall
                wrapMode: Text.Wrap
            }
        }

        // ── Summary tiles ───────────────────────────────────────────────────
        Flow {
            Layout.fillWidth: true
            spacing: Theme.space2
            Tile {
                caption: "Top bar"
                value: page.themeStore.barHeight + " px"
                detail: (page.themeStore.showDate ? "Date shown" : "Date hidden") + ", " + (page.themeStore.showSeconds ? "seconds on" : "seconds off")
            }
            Tile {
                caption: "Dock"
                value: page.themeStore.dockEnabled ? "Shown" : "Hidden"
                valueColor: page.themeStore.dockEnabled ? Pal.Palette.textPrimary : Pal.Palette.muted
                detail: (page.themeStore.dockAutoHide ? "Auto-hide on" : "Always visible") + ", icons " + page.themeStore.dockIconSize + " px"
            }
            Tile {
                caption: "Launcher"
                value: page.themeStore.launcherDefaultView === "grid" ? "Grid" : "List"
                detail: page.themeStore.launcherColumns + " columns"
            }
            Tile {
                caption: "Glass"
                value: Math.round(page.themeStore.glassOpacity * 100) + "%"
                detail: "Dock " + Math.round(page.themeStore.dockOpacity * 100) + "%, corner radius " + page.themeStore.cornerRadius
            }
        }

        // ── Wallpaper preview and accent swatches ──────────────────────────
        Flow {
            Layout.fillWidth: true
            spacing: Theme.space3

            Rectangle {
                width: 320; height: 180
                radius: Theme.radiusCardSet
                color: Pal.Palette.sidebar
                border.color: Pal.Palette.surfaceEdge
                clip: true
                Image {
                    id: preview
                    anchors.fill: parent
                    source: page.themeStore.wallpaperPath ? "file://" + encodeURI(page.themeStore.wallpaperPath) : ""
                    fillMode: page.themeStore.wallpaperFit === "contain" ? Image.PreserveAspectFit : Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                    sourceSize.width: 640
                    sourceSize.height: 360
                }
                Text {
                    visible: preview.status !== Image.Ready
                    anchors.centerIn: parent
                    text: preview.status === Image.Error ? "Wallpaper could not be loaded" : "No wallpaper selected"
                    color: Pal.Palette.muted
                    font.pixelSize: Theme.fontSmall
                }
                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: 34
                    color: Pal.Palette.window
                    opacity: 0.85
                    Text {
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 12 }
                        text: (page.themeStore.wallpaperPath ? page.themeStore.wallpaperPath.split("/").pop() : "Default")
                              + "  ·  " + page.themeStore.wallpaperFit
                        color: Pal.Palette.textSecondary
                        font.pixelSize: Theme.fontSmall
                        elide: Text.ElideMiddle
                        width: parent.width - 24
                    }
                }
            }

            Rectangle {
                width: 320; height: 180
                radius: Theme.radiusCardSet
                color: Pal.Palette.surface
                border.color: Pal.Palette.surfaceEdge
                ColumnLayout {
                    anchors { fill: parent; margins: 14 }
                    spacing: Theme.space2
                    Text { text: "ACCENT"; color: Pal.Palette.muted; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold; font.letterSpacing: 1.1 }
                    Flow {
                        Layout.fillWidth: true
                        spacing: Theme.space2
                        Repeater {
                            model: page.themeStore.accentSwatches
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool chosen: page.themeStore.accentColor === modelData.hex
                                width: 34; height: 34; radius: 17
                                color: modelData.hex
                                border.width: chosen ? 2 : 1
                                border.color: chosen ? Pal.Palette.textPrimary : Pal.Palette.controlEdge
                                ToolTip.visible: swMa.containsMouse
                                ToolTip.text: modelData.name
                                MouseArea {
                                    id: swMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: page.themeStore.set("theme.accent", modelData.hex)
                                }
                            }
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "Click a swatch to change the accent. Applies to the bar, dock and Settings."
                        color: Pal.Palette.textSecondary
                        font.pixelSize: Theme.fontSmall
                        wrapMode: Text.Wrap
                    }
                    Item { Layout.fillHeight: true }
                    SettingsButton { text: "Open Appearance"; onClicked: page.navigate("appearance") }
                }
            }
        }

        // ── Runtime services and configuration health ─────────────────────
        SettingsCard {
            title: "System integration"
            SettingsRow { label: "Levish backend"; hint: "Metrics, network, audio and power services"
                Text { text: page.backendRunning ? "Running" : "Not running"; color: page.backendRunning ? Pal.Palette.ok : Pal.Palette.warning; font.pixelSize: Theme.fontSmall } }
            SettingsRow { label: "Settings file"; hint: page.themeStore.configPath
                Text {
                    text: page.themeStore.status === "ok" ? "Valid" : (page.themeStore.status === "missing" ? "Not created yet" : "Needs attention")
                    color: page.themeStore.status === "ok" ? Pal.Palette.ok : Pal.Palette.danger
                    font.pixelSize: Theme.fontSmall
                } }
        }

        // ── Recent changes (this session only) ───────────────────────────
        SettingsCard {
            title: "Recent changes"
            Text {
                visible: page.themeStore.recentChanges.length === 0
                text: "No changes yet this session. Changes you make in Settings appear here until the shell restarts."
                color: Pal.Palette.muted
                font.pixelSize: Theme.fontSmall
                wrapMode: Text.Wrap
                width: parent.width
            }
            Repeater {
                model: page.themeStore.recentChanges
                delegate: SettingsRow {
                    required property var modelData
                    label: modelData.path
                    hint: modelData.time
                    Text { text: modelData.value; color: Pal.Palette.textSecondary; font.pixelSize: Theme.fontSmall; elide: Text.ElideRight; Layout.maximumWidth: 200 }
                }
            }
        }

        // ── Shortcuts ─────────────────────────────────────────────────────
        SettingsCard {
            title: "Customise"
            Flow {
                Layout.fillWidth: true
                spacing: Theme.space2
                SettingsButton { text: "Appearance"; onClicked: page.navigate("appearance") }
                SettingsButton { text: "Top bar"; onClicked: page.navigate("topbar") }
                SettingsButton { text: "Dock"; onClicked: page.navigate("dock") }
                SettingsButton { text: "Launcher"; onClicked: page.navigate("launcher") }
                SettingsButton { text: "Wallpaper"; onClicked: page.navigate("wallpaper") }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Levish " + Version.version + ". See About for runtime details."
            color: Pal.Palette.muted
            font.pixelSize: Theme.fontCaption
            wrapMode: Text.Wrap
        }
    }
}
