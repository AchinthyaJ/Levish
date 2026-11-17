// Levish — Unified continuous horizontal top bar.
// One full-width bar spanning the screen with 5 distinct logical zones and live reactivity.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import "../common" as C
import "../common/Theme.js" as Theme
import "." as B
import "../common" as Pal

PanelWindow {
    id: bar
    required property var store
    required property var themeStore

    signal perfHovered(bool v)
    signal statusClicked()
    signal powerClicked()
    signal settingsClicked()
    // A tray app was clicked and has a menu: shell.qml opens the styled menu under the icon.
    signal trayMenuRequested(var item, real x)

    property bool perfOpen: false
    property bool statusOpen: false
    property bool powerOpen: false
    property bool settingsOpen: false
    property int pendingDeleteWs: -1

    // Placement from Settings. Gap is the distance from the chosen edge, side margin from the left and right.
    readonly property bool atBottom: bar.themeStore ? bar.themeStore.barPosition === "bottom" : false
    readonly property int gapPx: bar.themeStore ? bar.themeStore.barGap : 0
    anchors { top: !atBottom; bottom: atBottom; left: true; right: true }
    margins { top: atBottom ? 0 : gapPx; bottom: atBottom ? gapPx : 0
              left: bar.themeStore ? bar.themeStore.barSideMargin : 0; right: bar.themeStore ? bar.themeStore.barSideMargin : 0 }
    // Unified: the bar is 4 px taller than its content. Islands: the window is exactly the island
    // height, so no empty strip sits under the islands and the panels can start right below them.
    readonly property int contentHeight: bar.themeStore && bar.themeStore.barHeight ? bar.themeStore.barHeight : Theme.barHeight
    // Height of each island or zone. Same in both modes: the islands are the window in islands mode, and
    // sit 4 px inside it in unified mode.
    readonly property int zoneH: contentHeight - 4
    implicitHeight: islands ? contentHeight - 4 : contentHeight + 4
    color: "transparent"
    exclusiveZone: bar.implicitHeight + bar.gapPx
    WlrLayershell.namespace: "levish-bar"
    WlrLayershell.layer: WlrLayer.Top

    Timer {
        id: cancelDeleteTimer
        interval: 4000
        onTriggered: bar.pendingDeleteWs = -1
    }

    Process { id: wsProc }
    Process { id: delProc }

    function switchWorkspace(wid) {
        bar.pendingDeleteWs = -1
        wsProc.running = false
        // Hyprland 0.57 reads dispatchers as Lua: the legacy "workspace N" form is rejected.
        wsProc.command = ["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + Number(wid) + " })"]
        wsProc.running = true
    }

    function addWorkspace() {
        bar.pendingDeleteWs = -1
        let maxId = 0
        const list = Hyprland.workspaces.values !== undefined ? Hyprland.workspaces.values : Hyprland.workspaces
        for (let i = 0; i < list.length; i++) {
            const wid = Number(list[i].id)
            if (wid > maxId) maxId = wid
        }
        const nextId = maxId > 0 ? (maxId + 1) : 1
        switchWorkspace(nextId)
    }

    function deleteWorkspace(wid) {
        let targetWs = 1
        const list = Hyprland.workspaces.values !== undefined ? Hyprland.workspaces.values : Hyprland.workspaces
        for (let i = 0; i < list.length; i++) {
            const id = Number(list[i].id)
            if (id !== wid) { targetWs = id; break }
        }
        delProc.running = false
        delProc.command = ["hyprctl", "dispatch", "movetoworkspacesilent", targetWs + ",workspace:" + wid]
        delProc.running = true
        bar.pendingDeleteWs = -1
    }

    // Coordinates for dropdown panels to anchor cleanly
    readonly property real perfLeft: {
        try {
            const pt = perfZone.mapToItem(null, 0, 0)
            return pt.x > 0 ? pt.x : 14
        } catch (e) {
            return 14
        }
    }
    readonly property real perfWidth: perfZone.width > 0 ? perfZone.width : 200

    readonly property real statusRight: {
        try {
            const pt = statusZone.mapToItem(null, 0, 0)
            const r = bar.width - (pt.x + statusZone.width)
            return (r > 0 && r < bar.width - 400) ? r : 14
        } catch (e) {
            return 14
        }
    }
    readonly property real statusWidth: statusZone.width > 0 ? statusZone.width : 160

    readonly property real powerRight: {
        try {
            const pt = powerBtn.mapToItem(null, 0, 0)
            const r = bar.width - (pt.x + powerBtn.width)
            return (r > 0 && r < bar.width - 100) ? r : 14
        } catch (e) {
            return 14
        }
    }
    readonly property real powerWidth: powerBtn.width > 0 ? powerBtn.width : 26

    // Input region. Unified: the whole bar. Islands: only the capsules, so the gaps let clicks through.
    mask: bar.islands ? islandMask : barMask
    Region {
        id: barMask
        item: barBackground
    }
    Region {
        id: islandMask
        Region { item: capPerf }
        Region { item: capWork }
        Region { item: capTitle }
        Region { item: capClock }
        Region { item: capStatus }
        Region { item: capTray }
        // The settings and power buttons are not in a capsule, so they must be in the input region too.
        Region { item: settingsBtn }
        Region { item: powerBtn }
    }

    // ── Presentation mode ──────────────────────────────────────────
    // "unified": one continuous glass bar. "islands": each zone is its own floating capsule, and
    // clicks pass between them. Both modes use the same zones, widgets and popups.
    readonly property bool islands: bar.themeStore ? bar.themeStore.barMode === "islands" : false
    readonly property int islandRadius: bar.themeStore ? bar.themeStore.islandRadius : 16
    readonly property int islandGap: bar.themeStore ? bar.themeStore.islandGap : 20
    // Breathing room inside each island, on each side of its contents.
    readonly property int islandPad: bar.themeStore ? bar.themeStore.islandPadding : 10

    // ── Continuous unified bar surface ─────────────────────────────
    Rectangle {
        id: barBackground
        anchors.fill: parent
        color: bar.islands ? "transparent" : (bar.themeStore ? bar.themeStore.glassColor : Pal.Palette.glass)
        radius: bar.islands ? 0 : (bar.themeStore ? bar.themeStore.barRadius : 0)
        // Outline is off by default (bar.border = 0), so the bar stays a plain glass surface.
        border.width: bar.themeStore && bar.themeStore.barBorder > 0 ? 1 : 0
        border.color: Qt.rgba(1, 1, 1, bar.themeStore ? bar.themeStore.barBorder : 0)

        Behavior on color { ColorAnimation { duration: Theme.dur(180) } }

        // Cancel workspace delete mode if clicked elsewhere on the bar
        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: bar.pendingDeleteWs = -1
        }

        // ── Island capsules (drawn only in islands mode) ───────────────
        // Each capsule takes the geometry of the zone it backs, so layout changes follow. Zero size
        // when hidden, so its input region disappears with it.
        Rectangle {
            id: capPerf
            readonly property bool on: bar.islands && perfZone.visible
            x: rowL.x + perfZone.x - bar.islandPad; y: 4
            width: on ? perfZone.width + 2 * bar.islandPad : 0; height: on ? bar.zoneH : 0
            radius: bar.islandRadius; color: bar.themeStore ? bar.themeStore.glassColor : Pal.Palette.glass
        }
        Rectangle {
            id: capWork
            readonly property bool on: bar.islands && workspaceZone.visible
            x: rowL.x + workspaceZone.x - bar.islandPad; y: 4
            width: on ? workspaceZone.width + 2 * bar.islandPad : 0; height: on ? bar.zoneH : 0
            radius: bar.islandRadius; color: bar.themeStore ? bar.themeStore.glassColor : Pal.Palette.glass
        }
        Rectangle {
            id: capTitle
            readonly property bool on: bar.islands && titleZone.visible
            x: rowL.x + titleZone.x - bar.islandPad; y: 4
            width: on ? titleZone.width + 2 * bar.islandPad : 0; height: on ? bar.zoneH : 0
            radius: bar.islandRadius; color: bar.themeStore ? bar.themeStore.glassColor : Pal.Palette.glass
        }
        Rectangle {
            id: capClock
            readonly property bool on: bar.islands && clockZone.visible
            x: rowL.x + clockZone.x - bar.islandPad; y: 4
            width: on ? clockZone.width + 2 * bar.islandPad : 0; height: on ? bar.zoneH : 0
            radius: bar.islandRadius; color: bar.themeStore ? bar.themeStore.glassColor : Pal.Palette.glass
        }
        Rectangle {
            id: capStatus
            readonly property bool on: bar.islands && statusZone.visible
            x: rowL.x + rightGroup.x + statusZone.x - bar.islandPad; y: 4
            width: on ? statusZone.width + 2 * bar.islandPad : 0; height: on ? bar.zoneH : 0
            radius: bar.islandRadius; color: bar.themeStore ? bar.themeStore.glassColor : Pal.Palette.glass
        }
        Rectangle {
            id: capTray
            readonly property bool on: bar.islands && trayZone.visible
            x: rowL.x + rightGroup.x + trayZone.x - bar.islandPad; y: 4
            width: on ? trayZone.width + 2 * bar.islandPad : 0; height: on ? bar.zoneH : 0
            radius: bar.islandRadius; color: bar.themeStore ? bar.themeStore.glassColor : Pal.Palette.glass
        }

        // ── Five-Zone Content Layout ────────────────────────────────
        RowLayout {
            id: rowL
            // Islands: the outer capsules reach the bar's edges, so the group is as wide as the bar.
            // Unified: the usual inset from the edges.
            anchors { fill: parent; leftMargin: bar.islands ? bar.islandPad : 14; rightMargin: bar.islands ? bar.islandPad : 14 }
            spacing: bar.islands ? bar.islandGap : 12

            // =========================================================
            // ZONE 1: LEFT — Performance Indicators
            // =========================================================
            Rectangle {
                id: perfZone
                visible: bar.themeStore ? bar.themeStore.showPerf : true
                implicitWidth: perfRow.childrenRect.width + 16
                implicitHeight: bar.zoneH
                radius: 8
                color: perfMA.containsMouse || bar.perfOpen ? Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.094) : "transparent"
                border.color: perfMA.containsMouse || bar.perfOpen ? Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.149) : "transparent"
                border.width: 1
                Behavior on color { ColorAnimation { duration: Theme.dur(150) } }
                Behavior on border.color { ColorAnimation { duration: Theme.dur(150) } }

                Row {
                    id: perfRow
                    x: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    // CPU Indicator
                    Row {
                        spacing: 5
                        anchors.verticalCenter: parent.verticalCenter
                        C.Icon {
                            kind: "cpu"
                            tint: bar.themeStore ? bar.themeStore.accentColor : Theme.cpu
                            width: 15; height: 15
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: Math.round(bar.store.metrics.cpu_percent) + "%"
                            color: Pal.Palette.text
                            font.pixelSize: Theme.fs(12)
                            font.family: "JetBrains Mono"
                            font.weight: Font.Medium
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // RAM Indicator
                    Row {
                        spacing: 5
                        anchors.verticalCenter: parent.verticalCenter
                        C.Icon {
                            kind: "ram"
                            tint: bar.themeStore ? bar.themeStore.accentColor : Theme.memory
                            width: 15; height: 15
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: Math.round(bar.store.metrics.ram_percent) + "%"
                            color: Pal.Palette.text
                            font.pixelSize: Theme.fs(12)
                            font.family: "JetBrains Mono"
                            font.weight: Font.Medium
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // GPU Indicator (if available)
                    Row {
                        spacing: 5
                        visible: (bar.themeStore ? bar.themeStore.showGpu : true) && bar.store.metrics.gpu_percent !== null && bar.store.metrics.gpu_percent !== undefined
                        anchors.verticalCenter: parent.verticalCenter
                        C.Icon {
                            kind: "gpu"
                            tint: bar.themeStore ? bar.themeStore.accentColor : Theme.gpu
                            width: 15; height: 15
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: Math.round(bar.store.metrics.gpu_percent || 0) + "%"
                            color: Pal.Palette.text
                            font.pixelSize: Theme.fs(12)
                            font.family: "JetBrains Mono"
                            font.weight: Font.Medium
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // CPU Temperature (if available)
                    Row {
                        spacing: 4
                        visible: (bar.themeStore ? bar.themeStore.showTemp : true) && bar.store.metrics.cpu_temp !== null && bar.store.metrics.cpu_temp !== undefined
                        anchors.verticalCenter: parent.verticalCenter
                        C.Icon {
                            kind: "thermo"
                            tint: Pal.Palette.muted
                            width: 14; height: 14
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: Math.round(bar.store.metrics.cpu_temp || 0) + "°"
                            color: Pal.Palette.muted
                            font.pixelSize: Theme.fs(12)
                            font.family: "JetBrains Mono"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                MouseArea {
                    id: perfMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: bar.perfHovered(true)
                    onExited: bar.perfHovered(false)
                }
            }

            // Divider between Left and Left-Center
            Rectangle {
                implicitWidth: 1; implicitHeight: 16
                color: Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.094)
            }

            // =========================================================
            // ZONE 2: LEFT-CENTER — Workspaces (Bigger pills, switch, add +, right-click -> trash -> double click delete)
            // =========================================================
            Row {
                id: workspaceZone
                visible: bar.themeStore ? bar.themeStore.showWorkspaces : true
                spacing: 8
                Layout.alignment: Qt.AlignVCenter

                Repeater {
                    model: Hyprland.workspaces
                    delegate: Item {
                        required property var modelData
                        readonly property bool isPendingDelete: bar.pendingDeleteWs === modelData.id
                        readonly property int pillWidth: bar.themeStore ? bar.themeStore.workspaceFocusedWidth : 40
                        readonly property int pillHeight: bar.themeStore ? bar.themeStore.workspaceHeight : 14
                        readonly property int pillRadius: bar.themeStore ? bar.themeStore.workspaceRadius : 7

                        width: isPendingDelete ? 22 : (modelData.focused ? pillWidth : pillHeight)
                        height: isPendingDelete ? 22 : pillHeight
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on width { NumberAnimation { duration: Theme.dur(240); easing.type: Easing.OutBack } }

                        // Standard workspace pill
                        Rectangle {
                            anchors.fill: parent
                            visible: !isPendingDelete
                            radius: pillRadius
                            color: modelData.focused ? (bar.themeStore ? bar.themeStore.accentColor : Pal.Palette.accent) : (modelData.active ? Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.867) : Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.267))
                            border.color: modelData.focused ? (bar.themeStore ? bar.themeStore.accentColor : Pal.Palette.accent) : Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.133)
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: Theme.dur(180) } }
                        }

                        // Trash replacement mode
                        Rectangle {
                            anchors.fill: parent
                            visible: isPendingDelete
                            radius: 6
                            color: "#33e94560"
                            border.color: "#e94560"
                            border.width: 1

                            C.Icon {
                                anchors.centerIn: parent
                                width: 14; height: 14
                                kind: "trash"
                                tint: "#f0708a"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton

                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton) {
                                    bar.pendingDeleteWs = modelData.id
                                    cancelDeleteTimer.restart()
                                } else {
                                    if (!isPendingDelete) {
                                        bar.switchWorkspace(modelData.id)
                                    }
                                }
                            }

                            onDoubleClicked: mouse => {
                                if (isPendingDelete) {
                                    bar.deleteWorkspace(modelData.id)
                                } else {
                                    bar.switchWorkspace(modelData.id)
                                }
                            }
                        }
                    }
                }

                // Add Workspace (+) Button
                Rectangle {
                    width: 20
                    height: 20
                    radius: 10
                    anchors.verticalCenter: parent.verticalCenter
                    color: addMA.containsMouse ? Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.149) : Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.071)
                    border.color: addMA.containsMouse ? (bar.themeStore ? bar.themeStore.accentColor : Pal.Palette.accent) : Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.133)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: Theme.dur(150) } }
                    Behavior on border.color { ColorAnimation { duration: Theme.dur(150) } }

                    C.Icon {
                        anchors.centerIn: parent
                        width: 11; height: 11
                        kind: "plus"
                        tint: addMA.containsMouse ? (bar.themeStore ? bar.themeStore.accentColor : Pal.Palette.accent) : Pal.Palette.muted
                    }

                    MouseArea {
                        id: addMA
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bar.addWorkspace()
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // =========================================================
            // ZONE 3: CENTER — Active Window Title
            // =========================================================
            Row {
                id: titleZone
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                spacing: 8
                visible: bar.themeStore ? bar.themeStore.showWindowTitle : true

                // A small accent dot marks the active window.
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 6; height: 6; radius: 3
                    color: Pal.Palette.accent
                }

                Text {
                    text: {
                        const title = bar.store.activeTitle ? bar.store.activeTitle.trim() : ""
                        if (title.length > 0) return title
                        const cls = bar.store.activeClass ? bar.store.activeClass.trim() : ""
                        if (cls.length > 0) return cls
                        return "Desktop"
                    }
                    color: Pal.Palette.text
                    font.pixelSize: Theme.fs(15)
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.3
                    elide: Text.ElideMiddle
                    maximumLineCount: 1
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, 460)
                    horizontalAlignment: Text.AlignLeft
                }
            }

            Item { Layout.fillWidth: true }

            // =========================================================
            // ZONE 4: CENTER-RIGHT — Clock
            // =========================================================
            Rectangle {
                id: clockZone
                visible: bar.themeStore ? bar.themeStore.showClock : true
                implicitWidth: clockRow.childrenRect.width + 12
                implicitHeight: bar.zoneH
                radius: 6
                color: "transparent"
                Layout.alignment: Qt.AlignVCenter

                Row {
                    id: clockRow
                    anchors.centerIn: parent
                    spacing: 8

                    B.Clock {
                        themeStore: bar.themeStore
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // Divider between Clock and Right System zone
            Rectangle {
                implicitWidth: 1; implicitHeight: 16
                color: Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.094)
            }

            // =========================================================
            // ZONE 5: RIGHT — System Indicators, Settings & Power
            // =========================================================
            Row {
                id: rightGroup
                Layout.alignment: Qt.AlignVCenter
                spacing: 8

                // System indicators group (Wi-Fi, Bluetooth, Audio, Battery)
                Rectangle {
                    id: statusZone
                    visible: bar.themeStore ? bar.themeStore.showStatus : true
                    implicitWidth: statusRow.childrenRect.width + 14
                    implicitHeight: bar.zoneH
                    radius: 8
                    color: statusMA.containsMouse || bar.statusOpen ? Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.094) : "transparent"
                    border.color: statusMA.containsMouse || bar.statusOpen ? Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.149) : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: Theme.dur(150) } }
                    Behavior on border.color { ColorAnimation { duration: Theme.dur(150) } }

                    Row {
                        id: statusRow
                        x: 7
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        // Wi-Fi
                        C.Icon {
                            width: 15; height: 15
                            kind: bar.store.network.connected ? "wifi" : "wifiOff"
                            tint: bar.store.network.connected ? (bar.themeStore ? bar.themeStore.accentColor : Pal.Palette.accent) : Pal.Palette.muted
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Audio Volume + mini level bar
                        Row {
                            spacing: 6
                            anchors.verticalCenter: parent.verticalCenter

                            C.Icon {
                                width: 15; height: 15
                                kind: bar.store.audio.muted ? "mute" : (bar.store.audio.volume > 33 ? "volume" : "volLow")
                                tint: bar.store.audio.muted ? Pal.Palette.muted : Pal.Palette.text
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                width: 36; height: 4; radius: 2
                                color: Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.133)
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    width: parent.width * Math.max(0, Math.min(1, bar.store.audio.volume / 100))
                                    height: parent.height; radius: 2
                                    color: bar.store.audio.muted ? Pal.Palette.muted : (bar.themeStore ? bar.themeStore.accentColor : Pal.Palette.accent)
                                    Behavior on width { NumberAnimation { duration: Theme.dur(200); easing.type: Easing.OutCubic } }
                                }
                            }
                        }

                        // Battery
                        Row {
                            spacing: 5
                            anchors.verticalCenter: parent.verticalCenter
                            B.BatteryIcon {
                                level: bar.store.battery.percent
                                charging: bar.store.battery.charging
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: bar.store.battery.percent + "%"
                                color: Pal.Palette.text
                                font.pixelSize: Theme.fs(11)
                                font.family: "JetBrains Mono"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    MouseArea {
                        id: statusMA
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bar.statusClicked()
                    }
                }

                // Background apps (system tray). Sized and padded like the status group beside it.
                // Left click opens the app's menu, as other shells do; an app with no menu is activated
                // instead. Right click opens the menu when there is one, or runs the secondary action.
                Rectangle {
                    id: trayZone
                    visible: (bar.themeStore ? bar.themeStore.showTray : true) && SystemTray.items.values.length > 0
                    implicitWidth: trayRow.childrenRect.width + 14
                    implicitHeight: bar.zoneH
                    radius: 8
                    color: "transparent"
                    border.width: 1
                    border.color: "transparent"

                    Row {
                        id: trayRow
                        x: 7
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Repeater {
                            model: SystemTray.items
                            Item {
                                id: trayItem
                                required property var modelData
                                width: 20; height: 20
                                anchors.verticalCenter: parent.verticalCenter

                                Image {
                                    anchors.centerIn: parent
                                    width: 16; height: 16
                                    // Already a usable URL from Quickshell (image://icon/… or image://qspixmap/…), so used as-is.
                                    source: trayItem.modelData.icon
                                    sourceSize.width: 32; sourceSize.height: 32
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    smooth: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: (mouse) => {
                                        const item = trayItem.modelData
                                        const p = mapToItem(null, mouse.x, mouse.y)
                                        // Any click on an app with a menu opens the styled menu under the icon.
                                        if (item.hasMenu) bar.trayMenuRequested(item, p.x)
                                        else if (mouse.button === Qt.LeftButton) item.activate()
                                        else item.secondaryActivate()
                                    }
                                }
                            }
                        }
                    }
                }

                // =======================================================
                // BIG, PREVALENT, UNMISTAKABLE SETTINGS BUTTON
                // =======================================================
                Rectangle {
                    id: settingsBtn
                    implicitWidth: 32; implicitHeight: 32
                    radius: 16
                    anchors.verticalCenter: parent.verticalCenter
                    color: setMA.containsMouse || bar.settingsOpen
                           ? (bar.themeStore ? Qt.rgba(0.2, 0.4, 0.5, 0.45) : Qt.rgba(Pal.Palette.accent.r, Pal.Palette.accent.g, Pal.Palette.accent.b, 0.2))
                           : Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.094)
                    border.color: setMA.containsMouse || bar.settingsOpen
                                  ? (bar.themeStore ? bar.themeStore.accentColor : Pal.Palette.accent)
                                  : Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.2)
                    border.width: 1.5
                    scale: setMA.containsMouse ? 1.08 : 1.0
                    Behavior on scale { NumberAnimation { duration: Theme.dur(150); easing.type: Easing.OutBack } }
                    Behavior on color { ColorAnimation { duration: Theme.dur(150) } }
                    Behavior on border.color { ColorAnimation { duration: Theme.dur(150) } }

                    C.Icon {
                        anchors.centerIn: parent
                        width: 18; height: 18
                        kind: "gear"
                        tint: setMA.containsMouse || bar.settingsOpen
                              ? (bar.themeStore ? bar.themeStore.accentColor : Pal.Palette.accent)
                              : "#ffffff"
                    }

                    MouseArea {
                        id: setMA
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bar.settingsClicked()
                    }
                }

                // Power Button (5-option power menu)
                Rectangle {
                    id: powerBtn
                    implicitWidth: 28; implicitHeight: 28
                    radius: 14
                    color: pwrMA.containsMouse || bar.powerOpen ? "#33e94560" : Qt.rgba(Pal.Palette.ink.r, Pal.Palette.ink.g, Pal.Palette.ink.b, 0.078)
                    border.color: pwrMA.containsMouse || bar.powerOpen ? "#66e94560" : "transparent"
                    border.width: 1
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: Theme.dur(150) } }

                    C.Icon {
                        anchors.centerIn: parent
                        width: 14; height: 14
                        kind: "power"
                        tint: pwrMA.containsMouse || bar.powerOpen ? "#f0708a" : (bar.themeStore ? bar.themeStore.accentColor : Pal.Palette.accent)
                    }

                    MouseArea {
                        id: pwrMA
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bar.powerClicked()
                    }
                }
            }
        }
    }
}
