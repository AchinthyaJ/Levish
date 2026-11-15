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

PanelWindow {
    id: bar
    required property var store
    required property var themeStore

    signal perfHovered(bool v)
    signal statusClicked()
    signal powerClicked()
    signal settingsClicked()

    property bool perfOpen: false
    property bool statusOpen: false
    property bool powerOpen: false
    property bool settingsOpen: false
    property int pendingDeleteWs: -1

    anchors { top: true; left: true; right: true }
    implicitHeight: (bar.themeStore && bar.themeStore.barHeight) ? (bar.themeStore.barHeight + 4) : (Theme.barHeight + 4)
    color: "transparent"
    exclusiveZone: bar.implicitHeight
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
        wsProc.command = ["hyprctl", "dispatch", "workspace", String(wid)]
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

    // ── Continuous unified bar surface ─────────────────────────────
    Rectangle {
        id: barBackground
        anchors.fill: parent
        color: bar.themeStore ? bar.themeStore.glassColor : Theme.glass
        // No outline: the bar is a plain glass surface, and windows start directly below it.
        border.width: 0

        Behavior on color { ColorAnimation { duration: 180 } }

        // Cancel workspace delete mode if clicked elsewhere on the bar
        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: bar.pendingDeleteWs = -1
        }

        // ── Five-Zone Content Layout ────────────────────────────────
        RowLayout {
            anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
            spacing: 12

            // =========================================================
            // ZONE 1: LEFT — Performance Indicators
            // =========================================================
            Rectangle {
                id: perfZone
                implicitWidth: perfRow.childrenRect.width + 16
                implicitHeight: bar.height - 8
                radius: 8
                color: perfMA.containsMouse || bar.perfOpen ? "#18ffffff" : "transparent"
                border.color: perfMA.containsMouse || bar.perfOpen ? "#26ffffff" : "transparent"
                border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

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
                            color: Theme.text
                            font.pixelSize: 12
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
                            color: Theme.text
                            font.pixelSize: 12
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
                            color: Theme.text
                            font.pixelSize: 12
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
                            tint: Theme.muted
                            width: 14; height: 14
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: Math.round(bar.store.metrics.cpu_temp || 0) + "°"
                            color: Theme.muted
                            font.pixelSize: 12
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
                color: "#18ffffff"
            }

            // =========================================================
            // ZONE 2: LEFT-CENTER — Workspaces (Bigger pills, switch, add +, right-click -> trash -> double click delete)
            // =========================================================
            Row {
                id: workspaceZone
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
                        Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutBack } }

                        // Standard workspace pill
                        Rectangle {
                            anchors.fill: parent
                            visible: !isPendingDelete
                            radius: pillRadius
                            color: modelData.focused ? (bar.themeStore ? bar.themeStore.accentColor : Theme.accent) : (modelData.active ? "#ddffffff" : "#44ffffff")
                            border.color: modelData.focused ? (bar.themeStore ? bar.themeStore.accentColor : Theme.accent) : "#22ffffff"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 180 } }
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
                    color: addMA.containsMouse ? "#26ffffff" : "#12ffffff"
                    border.color: addMA.containsMouse ? (bar.themeStore ? bar.themeStore.accentColor : Theme.accent) : "#22ffffff"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    C.Icon {
                        anchors.centerIn: parent
                        width: 11; height: 11
                        kind: "plus"
                        tint: addMA.containsMouse ? (bar.themeStore ? bar.themeStore.accentColor : Theme.accent) : Theme.muted
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
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                spacing: 8
                Layout.maximumWidth: 420

                Text {
                    text: {
                        const title = bar.store.activeTitle ? bar.store.activeTitle.trim() : ""
                        if (title.length > 0) return title
                        const cls = bar.store.activeClass ? bar.store.activeClass.trim() : ""
                        if (cls.length > 0) return cls
                        return "Desktop"
                    }
                    color: Theme.text
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    elide: Text.ElideMiddle
                    maximumLineCount: 1
                    width: Math.min(implicitWidth, 380)
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Item { Layout.fillWidth: true }

            // =========================================================
            // ZONE 4: CENTER-RIGHT — Clock
            // =========================================================
            Rectangle {
                id: clockZone
                implicitWidth: clockRow.childrenRect.width + 12
                implicitHeight: bar.height - 8
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
                color: "#18ffffff"
            }

            // =========================================================
            // ZONE 5: RIGHT — System Indicators, Settings & Power
            // =========================================================
            Row {
                Layout.alignment: Qt.AlignVCenter
                spacing: 8

                // System indicators group (Wi-Fi, Bluetooth, Audio, Battery)
                Rectangle {
                    id: statusZone
                    implicitWidth: statusRow.childrenRect.width + 14
                    implicitHeight: bar.height - 8
                    radius: 8
                    color: statusMA.containsMouse || bar.statusOpen ? "#18ffffff" : "transparent"
                    border.color: statusMA.containsMouse || bar.statusOpen ? "#26ffffff" : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Row {
                        id: statusRow
                        x: 7
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        // Wi-Fi
                        C.Icon {
                            width: 15; height: 15
                            kind: bar.store.network.connected ? "wifi" : "wifiOff"
                            tint: bar.store.network.connected ? (bar.themeStore ? bar.themeStore.accentColor : Theme.accent) : Theme.muted
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Audio Volume + mini level bar
                        Row {
                            spacing: 6
                            anchors.verticalCenter: parent.verticalCenter

                            C.Icon {
                                width: 15; height: 15
                                kind: bar.store.audio.muted ? "mute" : (bar.store.audio.volume > 33 ? "volume" : "volLow")
                                tint: bar.store.audio.muted ? Theme.muted : Theme.text
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                width: 36; height: 4; radius: 2
                                color: "#22ffffff"
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    width: parent.width * Math.max(0, Math.min(1, bar.store.audio.volume / 100))
                                    height: parent.height; radius: 2
                                    color: bar.store.audio.muted ? Theme.muted : (bar.themeStore ? bar.themeStore.accentColor : Theme.accent)
                                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
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
                                color: Theme.text
                                font.pixelSize: 11
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

                // System Tray (if items present)
                Row {
                    visible: SystemTray.items.values.length > 0
                    spacing: 8
                    anchors.verticalCenter: parent.verticalCenter

                    Repeater {
                        model: SystemTray.items
                        Image {
                            required property var modelData
                            width: 16; height: 16
                            source: modelData.icon
                            sourceSize.width: 16; sourceSize.height: 16
                            anchors.verticalCenter: parent.verticalCenter
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: modelData.activate()
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
                           ? (bar.themeStore ? Qt.rgba(0.2, 0.4, 0.5, 0.45) : "#33c8f7ef")
                           : "#18ffffff"
                    border.color: setMA.containsMouse || bar.settingsOpen
                                  ? (bar.themeStore ? bar.themeStore.accentColor : Theme.accent)
                                  : "#33ffffff"
                    border.width: 1.5
                    scale: setMA.containsMouse ? 1.08 : 1.0
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    C.Icon {
                        anchors.centerIn: parent
                        width: 18; height: 18
                        kind: "gear"
                        tint: setMA.containsMouse || bar.settingsOpen
                              ? (bar.themeStore ? bar.themeStore.accentColor : Theme.accent)
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
                    color: pwrMA.containsMouse || bar.powerOpen ? "#33e94560" : "#14ffffff"
                    border.color: pwrMA.containsMouse || bar.powerOpen ? "#66e94560" : "transparent"
                    border.width: 1
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 150 } }

                    C.Icon {
                        anchors.centerIn: parent
                        width: 14; height: 14
                        kind: "power"
                        tint: pwrMA.containsMouse || bar.powerOpen ? "#f0708a" : (bar.themeStore ? bar.themeStore.accentColor : Theme.accent)
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
