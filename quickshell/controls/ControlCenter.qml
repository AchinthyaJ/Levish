// Levish Control Center: grows out of the status island on the right.
// Quick-settings tiles that open Wi-Fi and Bluetooth device lists, power profiles,
// a slim slider card, media and power. It closes when another window takes focus.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../common" as C
import "../common/Theme.js" as Theme
import "../bar" as B

PanelWindow {
    id: ccPanel

    required property var store
    property bool open: false
    // Geometry of the status island this panel drops from (screen pixels).
    property real anchorRight: 10
    property real anchorWidth: 240
    signal closeRequested()

    readonly property real flt: Theme.fillet
    readonly property real bodyW: 380
    readonly property string cardFill: "#12ffffff"
    readonly property string cardEdge: "#14ffffff"

    // "", "wifi" or "bluetooth": which device list is expanded.
    property string panelMode: ""
    property string passwordFor: ""     // SSID whose password field is showing

    // Margins are measured from the bar's bottom edge: one fillet above it
    // puts the fillet shoulders beside the island.
    anchors { top: true; right: true }
    margins {
        top:   0
        right: anchorRight - flt
    }
    implicitWidth:  bodyW + 2 * flt
    implicitHeight: col.implicitHeight + 32 + flt
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.namespace: "levish-cc"
    WlrLayershell.layer:     WlrLayer.Top
    // On demand, so the password field can take typing without holding focus permanently.
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    visible: open || body.opacity > 0.01

    onOpenChanged: if (!open) { panelMode = ""; passwordFor = "" }

    // ── State files written by the Python backend ─────────────────────────
    property var _media:      ({ player: "", playing: false, title: "", artist: "", art_url: "" })
    property var _bluetooth:  ({ enabled: false, devices: [] })
    property var _brightness: ({ percent: 50 })
    property var _wifi:       ({ networks: [] })
    property var _profiles:   ({ active: "", profiles: [] })

    FileView {
        path: "/tmp/levish/media.json"; watchChanges: true; onFileChanged: reload()
        onLoaded: { try { ccPanel._media = JSON.parse(text()) } catch(_) {} }
    }
    FileView {
        path: "/tmp/levish/bluetooth.json"; watchChanges: true; onFileChanged: reload()
        onLoaded: { try { ccPanel._bluetooth = JSON.parse(text()) } catch(_) {} }
    }
    FileView {
        path: "/tmp/levish/brightness.json"; watchChanges: true; onFileChanged: reload()
        onLoaded: { try { ccPanel._brightness = JSON.parse(text()) } catch(_) {} }
    }
    FileView {
        path: "/tmp/levish/wifi_scan.json"; watchChanges: true; onFileChanged: reload()
        onLoaded: { try { ccPanel._wifi = JSON.parse(text()) } catch(_) {} }
    }
    FileView {
        path: "/tmp/levish/power_profiles.json"; watchChanges: true; onFileChanged: reload()
        onLoaded: { try { ccPanel._profiles = JSON.parse(text()) } catch(_) {} }
    }

    // ── Control-socket helper ────────────────────────────────────────────
    // Sends one JSON command to the backend's Unix socket. Commands run one at a time.
    Process {
        id: ctrlProc
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onRunningChanged: {
            if (!running && ctrlProc._pending !== "") {
                ctrlProc.command = ctrlProc._pendingCmd
                ctrlProc._pending = ""
                ctrlProc.running = true
            }
        }
        property string _pending: ""
        property var _pendingCmd: []
    }

    function _cmd(obj) {
        const json = JSON.stringify(obj)
        const script = "import socket,sys;" +
                       "s=socket.socket(socket.AF_UNIX);" +
                       "s.connect('/tmp/levish/control.sock');" +
                       "s.sendall(sys.argv[1].encode());" +
                       "s.shutdown(socket.SHUT_WR);" +
                       "print(s.recv(4096).decode())"
        const cmd = ["python3", "-c", script, json]
        if (ctrlProc.running) {
            ctrlProc._pendingCmd = cmd
            ctrlProc._pending = json
        } else {
            ctrlProc.command = cmd
            ctrlProc.running = true
        }
    }

    function _connectWifi(ssid, password) {
        const v = password && password.length > 0 ? { ssid: ssid, password: password } : { ssid: ssid }
        _cmd({ cmd: "action", action: "connect_wifi", value: v })
        passwordFor = ""
    }

    // ── Wi-Fi radio switch: pending state until the radio actually changes ──
    readonly property bool wifiOn: store.network.radio !== undefined ? !!store.network.radio : !!store.network.connected
    property bool wifiBusy: false
    property bool wifiTargetOn: false
    onWifiOnChanged: if (wifiBusy && wifiOn === wifiTargetOn) { wifiBusy = false; wifiTimeout.stop() }
    function toggleWifi() {
        if (wifiBusy) return
        wifiTargetOn = !wifiOn
        wifiBusy = true
        wifiTimeout.restart()
        _cmd({ cmd: "action", action: "toggle_wifi" })
    }
    // Stop pulsing even if the radio never reports the change.
    Timer { id: wifiTimeout; interval: 20000; onTriggered: ccPanel.wifiBusy = false }

    readonly property var profileLabels: ({ "power-saver": "Saver", "balanced": "Balanced", "performance": "Performance" })

    // ── Animated body: grows out of the island ───────────────────────────
    Item {
        id: body
        anchors.fill: parent
        opacity: ccPanel.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        transform: Scale {
            origin.x: ccPanel.flt + ccPanel.bodyW - ccPanel.anchorWidth / 2
            origin.y: 0
            xScale: ccPanel.open ? 1 : Math.max(0.2, ccPanel.anchorWidth / (ccPanel.bodyW + 2 * ccPanel.flt))
            yScale: ccPanel.open ? 1 : 0.3
            Behavior on xScale { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
            Behavior on yScale { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
        }

        C.DropShape {
            anchors.fill: parent
            fillet: ccPanel.flt
            radius: Theme.dropRadius
            fillColor: Theme.glass
            edgeColor: Theme.glassEdge
        }

        ColumnLayout {
            id: col
            x: ccPanel.flt + 16; y: ccPanel.flt + 16
            width: ccPanel.bodyW - 32
            spacing: 12

            // ── Header: title, battery readout, close ───────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    text: "Control Centre"
                    color: Theme.text
                    font.pixelSize: 15; font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }
                RowLayout {
                    spacing: 5
                    Text {
                        text: ccPanel.store.battery.percent + "%"
                        color: Theme.muted; font.pixelSize: 11; font.family: "JetBrains Mono"
                    }
                    B.BatteryIcon {
                        Layout.preferredWidth: 28; Layout.preferredHeight: 18
                        level: ccPanel.store.battery.percent
                        charging: ccPanel.store.battery.charging
                    }
                }
                Rectangle {
                    implicitWidth: 24; implicitHeight: 24; radius: 12
                    color: closeMA.containsMouse ? "#22ffffff" : "transparent"
                    Behavior on color { ColorAnimation { duration: 140 } }
                    C.Icon { anchors.centerIn: parent; width: 11; height: 11; kind: "close"; tint: Theme.muted }
                    MouseArea {
                        id: closeMA; anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: ccPanel.closeRequested()
                    }
                }
            }

            // ── Media ─────────────────────────────────────────────────────
            Rectangle {
                visible: ccPanel._media.player !== ""
                Layout.fillWidth: true
                implicitHeight: mediaRow.implicitHeight + 24
                radius: 22
                color: ccPanel.cardFill
                border.color: ccPanel.cardEdge; border.width: 1

                RowLayout {
                    id: mediaRow
                    anchors { fill: parent; margins: 12 }
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 46; Layout.preferredHeight: 46
                        radius: 14; color: "#1ac8f7ef"; clip: true
                        Image {
                            id: artImg; anchors.fill: parent
                            source: ccPanel._media.art_url || ""
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                            asynchronous: true
                        }
                        C.Icon {
                            anchors.centerIn: parent
                            width: 18; height: 18
                            kind: "note"; tint: Theme.accent
                            visible: !artImg.visible
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text {
                            text: ccPanel._media.title || ""
                            color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold
                            elide: Text.ElideRight; Layout.fillWidth: true
                        }
                        Text {
                            text: ccPanel._media.artist || ""
                            color: Theme.muted; font.pixelSize: 10
                            elide: Text.ElideRight; Layout.fillWidth: true
                        }
                    }

                    Row {
                        spacing: 0
                        Repeater {
                            model: [
                                { kind: "prev", act: "previous",   accent: false },
                                { kind: ccPanel._media.playing ? "pause" : "play", act: "play_pause", accent: true },
                                { kind: "next", act: "next",       accent: false }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                implicitWidth: 30; implicitHeight: 30; radius: 15
                                color: btnMA.containsMouse ? "#18ffffff" : "transparent"
                                Behavior on color { ColorAnimation { duration: 120 } }
                                C.Icon {
                                    anchors.centerIn: parent
                                    width: modelData.accent ? 15 : 12; height: modelData.accent ? 15 : 12
                                    kind: modelData.kind
                                    tint: modelData.accent ? Theme.accent : Theme.text
                                }
                                MouseArea {
                                    id: btnMA; anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ccPanel._cmd({ cmd: "action", action: modelData.act })
                                }
                            }
                        }
                    }
                }
            }

            // ── Quick-settings tiles ──────────────────────────────────────
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 10; columnSpacing: 10

                Tile {
                    kind: ccPanel.wifiOn ? "wifi" : "wifiOff"
                    title: "Wi-Fi"
                    subtitle: !ccPanel.wifiOn ? "Off"
                              : (ccPanel.store.network.connected ? (ccPanel.store.network.ssid || "Connected") : "On · not connected")
                    checked: ccPanel.wifiOn
                    busy: ccPanel.wifiBusy
                    busyLabel: ccPanel.wifiTargetOn ? "Turning on…" : "Turning off…"
                    expandable: true
                    onToggled: ccPanel.toggleWifi()
                    onExpandRequested: {
                        ccPanel.panelMode = ccPanel.panelMode === "wifi" ? "" : "wifi"
                        if (ccPanel.panelMode === "wifi") ccPanel._cmd({ cmd: "action", action: "wifi_scan" })
                    }
                }
                Tile {
                    kind: "bluetooth"
                    title: "Bluetooth"
                    subtitle: ccPanel._bluetooth.enabled
                              ? (ccPanel._bluetooth.devices.length > 0 ? ccPanel._bluetooth.devices.length + " devices" : "On")
                              : "Off"
                    checked: ccPanel._bluetooth.enabled
                    expandable: true
                    onToggled: ccPanel._cmd({ cmd: "action", action: "toggle_bluetooth" })
                    onExpandRequested: {
                        ccPanel.panelMode = ccPanel.panelMode === "bluetooth" ? "" : "bluetooth"
                        if (ccPanel.panelMode === "bluetooth") ccPanel._cmd({ cmd: "action", action: "bt_scan" })
                    }
                }
            }

            // ── Device list: Wi-Fi networks or Bluetooth devices ──────────
            Rectangle {
                id: devicePanel
                visible: ccPanel.panelMode !== ""
                Layout.fillWidth: true
                implicitHeight: deviceCol.implicitHeight + 24
                radius: 22
                color: ccPanel.cardFill
                border.color: ccPanel.cardEdge; border.width: 1

                ColumnLayout {
                    id: deviceCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: ccPanel.panelMode === "wifi" ? "Wi-Fi networks" : "Bluetooth devices"
                            color: Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold
                            Layout.fillWidth: true
                        }
                        Text {
                            text: "Scan"
                            color: Theme.accent; font.pixelSize: 11
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: ccPanel._cmd({ cmd: "action", action: ccPanel.panelMode === "wifi" ? "wifi_scan" : "bt_scan" })
                            }
                        }
                    }

                    // Wi-Fi rows
                    Flickable {
                        visible: ccPanel.panelMode === "wifi"
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(wifiRows.implicitHeight, 220)
                        contentHeight: wifiRows.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        ColumnLayout {
                            id: wifiRows
                            width: parent.width
                            spacing: 4
                            Repeater {
                                model: ccPanel._wifi.networks
                                delegate: ColumnLayout {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        C.Icon {
                                            width: 16; height: 16
                                            kind: "wifi"
                                            tint: modelData.in_use ? Theme.accent : Theme.muted
                                        }
                                        Text {
                                            text: modelData.ssid
                                            color: modelData.in_use ? Theme.text : Theme.text
                                            font.pixelSize: 12; font.weight: modelData.in_use ? Font.DemiBold : Font.Normal
                                            elide: Text.ElideRight; Layout.fillWidth: true
                                        }
                                        Text {
                                            text: modelData.in_use ? "Connected" : (modelData.secured ? "Secured · " : "") + modelData.signal + "%"
                                            color: Theme.muted; font.pixelSize: 10
                                        }
                                        Rectangle {
                                            visible: !modelData.in_use
                                            implicitWidth: connTxt.implicitWidth + 16; implicitHeight: 22; radius: 11
                                            color: connMA.containsMouse ? "#24c8f7ef" : "#14ffffff"
                                            Text { id: connTxt; anchors.centerIn: parent; text: "Connect"; color: Theme.text; font.pixelSize: 10 }
                                            MouseArea {
                                                id: connMA; anchors.fill: parent; hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (modelData.secured) ccPanel.passwordFor = ccPanel.passwordFor === modelData.ssid ? "" : modelData.ssid
                                                    else ccPanel._connectWifi(modelData.ssid, "")
                                                }
                                            }
                                        }
                                    }
                                    RowLayout {
                                        visible: ccPanel.passwordFor === modelData.ssid
                                        Layout.fillWidth: true
                                        spacing: 6
                                        Layout.leftMargin: 24
                                        Rectangle {
                                            Layout.fillWidth: true
                                            implicitHeight: 28; radius: 10
                                            color: "#14ffffff"; border.color: ccPanel.cardEdge
                                            TextInput {
                                                id: pwField
                                                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                                verticalAlignment: TextInput.AlignVCenter
                                                color: Theme.text; font.pixelSize: 12
                                                echoMode: TextInput.Password
                                                clip: true
                                                focus: ccPanel.passwordFor === modelData.ssid
                                                onAccepted: ccPanel._connectWifi(modelData.ssid, text)
                                                Text {
                                                    anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                                                    visible: pwField.text.length === 0
                                                    text: "Password (blank for saved)"; color: Theme.muted; font.pixelSize: 11
                                                }
                                            }
                                        }
                                        Rectangle {
                                            implicitWidth: goTxt.implicitWidth + 16; implicitHeight: 28; radius: 10
                                            color: goMA.containsMouse ? "#33c8f7ef" : "#1ec8f7ef"
                                            Text { id: goTxt; anchors.centerIn: parent; text: "Join"; color: Theme.text; font.pixelSize: 11 }
                                            MouseArea {
                                                id: goMA; anchors.fill: parent; hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: ccPanel._connectWifi(modelData.ssid, pwField.text)
                                            }
                                        }
                                    }
                                }
                            }
                            Text {
                                visible: ccPanel._wifi.networks.length === 0
                                text: "No networks found. Press Scan."
                                color: Theme.muted; font.pixelSize: 11
                            }
                        }
                    }

                    // Bluetooth rows
                    Flickable {
                        visible: ccPanel.panelMode === "bluetooth"
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(btRows.implicitHeight, 220)
                        contentHeight: btRows.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        ColumnLayout {
                            id: btRows
                            width: parent.width
                            spacing: 4
                            Text {
                                visible: !ccPanel._bluetooth.enabled
                                text: "Bluetooth is off. Turn it on from the tile."
                                color: Theme.muted; font.pixelSize: 11
                            }
                            Repeater {
                                model: ccPanel._bluetooth.enabled ? ccPanel._bluetooth.devices : []
                                delegate: RowLayout {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    spacing: 8
                                    C.Icon {
                                        width: 16; height: 16
                                        kind: "bluetooth"
                                        tint: modelData.connected ? Theme.accent : Theme.muted
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        Text {
                                            text: modelData.name
                                            color: Theme.text; font.pixelSize: 12
                                            elide: Text.ElideRight; Layout.fillWidth: true
                                        }
                                        Text {
                                            text: modelData.connected ? "Connected" : (modelData.paired ? "Paired" : "Available")
                                            color: Theme.muted; font.pixelSize: 10
                                        }
                                    }
                                    Rectangle {
                                        implicitWidth: btTxt.implicitWidth + 16; implicitHeight: 22; radius: 11
                                        color: btMA.containsMouse ? "#24c8f7ef" : "#14ffffff"
                                        Text {
                                            id: btTxt; anchors.centerIn: parent
                                            text: modelData.connected ? "Disconnect" : (modelData.paired ? "Connect" : "Pair")
                                            color: Theme.text; font.pixelSize: 10
                                        }
                                        MouseArea {
                                            id: btMA; anchors.fill: parent; hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                const act = modelData.connected ? "bt_disconnect"
                                                          : (modelData.paired ? "bt_connect" : "bt_pair")
                                                ccPanel._cmd({ cmd: "action", action: act, value: modelData.address })
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Power profile ─────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                visible: ccPanel._profiles.profiles.length > 0
                Repeater {
                    model: ccPanel._profiles.profiles
                    delegate: Rectangle {
                        required property string modelData
                        readonly property bool active: ccPanel._profiles.active === modelData
                        Layout.fillWidth: true
                        implicitHeight: 34; radius: 17
                        color: active ? "#24c8f7ef" : (pMA.containsMouse ? "#1affffff" : "#12ffffff")
                        border.width: 1
                        border.color: active ? "#40c8f7ef" : "#14ffffff"
                        Behavior on color { ColorAnimation { duration: 160 } }
                        Text {
                            anchors.centerIn: parent
                            text: ccPanel.profileLabels[modelData] || modelData
                            color: active ? Theme.accent : Theme.text
                            font.pixelSize: 11; font.weight: active ? Font.DemiBold : Font.Normal
                        }
                        MouseArea {
                            id: pMA; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ccPanel._cmd({ cmd: "action", action: "power_profile", value: modelData })
                        }
                    }
                }
            }

            // ── Sliders card ──────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: sliders.implicitHeight + 32
                radius: 22
                color: ccPanel.cardFill
                border.color: ccPanel.cardEdge; border.width: 1

                ColumnLayout {
                    id: sliders
                    anchors { fill: parent; margins: 16 }
                    spacing: 18

                    SleekSlider {
                        kind: ccPanel.store.audio.muted ? "mute"
                              : ccPanel.store.audio.volume > 33 ? "volume" : "volLow"
                        label: "Volume"
                        value: ccPanel.store.audio.muted ? 0 : ccPanel.store.audio.volume
                        muted: ccPanel.store.audio.muted
                        onMoved: (v) => ccPanel._cmd({ cmd: "action", action: "set_volume", value: v })
                    }
                    SleekSlider {
                        kind: "sun"
                        label: "Brightness"
                        lo: 5
                        value: ccPanel._brightness.percent
                        onMoved: (v) => ccPanel._cmd({ cmd: "action", action: "set_brightness", value: v })
                    }
                }
            }

            // ── Power row ─────────────────────────────────────────────────
            GridLayout {
                Layout.fillWidth: true
                Layout.topMargin: 2
                columns: 4
                columnSpacing: 8

                Repeater {
                    model: [
                        { kind: "lock",    label: "Lock",    act: "lock",     hot: false },
                        { kind: "moon",    label: "Sleep",   act: "suspend",  hot: false },
                        { kind: "restart", label: "Restart", act: "restart",  hot: false },
                        { kind: "power",   label: "Power",   act: "shutdown", hot: true  }
                    ]
                    delegate: ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 6

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 50; radius: 18
                            color: actMA.containsMouse
                                   ? (modelData.hot ? "#33e94560" : "#22ffffff")
                                   : "#12ffffff"
                            border.color: "#14ffffff"; border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                            C.Icon {
                                anchors.centerIn: parent
                                width: 18; height: 18
                                kind: modelData.kind
                                tint: modelData.hot ? "#f0708a" : Theme.text
                            }
                            MouseArea {
                                id: actMA; anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ccPanel._cmd({ cmd: "action", action: modelData.act })
                            }
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: modelData.label
                            color: Theme.muted; font.pixelSize: 9
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 2 }
        }
    }
}
