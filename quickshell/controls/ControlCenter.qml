// Levish Control Center: grows out of the status island on the right.
// Quick-settings tiles, a slim slider card, media and power, all on the island's surface.
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
    property real anchorRight: 10   // distance from the screen's right edge to the island's right edge
    property real anchorWidth: 240

    readonly property real flt: Theme.fillet
    readonly property real bodyW: 340
    readonly property string cardFill: "#12ffffff"
    readonly property string cardEdge: "#14ffffff"

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
    visible: open || body.opacity > 0.01

    // ── Extra state not in the main Data store ───────────────────────────
    property var _media:      ({ player: "", playing: false, title: "", artist: "", art_url: "" })
    property var _bluetooth:  ({ enabled: false, devices: [] })
    property var _brightness: ({ percent: 50 })

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

    // ── Control-socket helper ────────────────────────────────────────────
    // Uses Python3 to send JSON to the Unix control socket.
    // nc is not available on this system; python3 is always present.
    Process {
        id: ctrlProc
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        // onRunningChanged lets us re-trigger immediately after a command finishes.
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
        // Inline Python3 that opens the UNIX socket, sends the JSON, reads response.
        const script = "import socket,sys;" +
                       "s=socket.socket(socket.AF_UNIX);" +
                       "s.connect('/tmp/levish/control.sock');" +
                       "s.sendall(sys.argv[1].encode());" +
                       "s.shutdown(socket.SHUT_WR);" +
                       "print(s.recv(4096).decode())"
        const cmd = ["python3", "-c", script, json]
        if (ctrlProc.running) {
            // Queue: will fire from onRunningChanged when current command finishes.
            ctrlProc._pendingCmd = cmd
            ctrlProc._pending = json
        } else {
            ctrlProc.command = cmd
            ctrlProc.running = true
        }
    }

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
                        onClicked: ccPanel.open = false
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
                    kind: ccPanel.store.network.connected ? "wifi" : "wifiOff"
                    title: "Wi-Fi"
                    subtitle: ccPanel.store.network.connected ? (ccPanel.store.network.ssid || "Connected") : "Off"
                    checked: ccPanel.store.network.connected
                    onToggled: ccPanel._cmd({ cmd: "action", action: "toggle_wifi" })
                }
                Tile {
                    kind: "bluetooth"
                    title: "Bluetooth"
                    subtitle: ccPanel._bluetooth.enabled
                              ? (ccPanel._bluetooth.devices.length > 0 ? ccPanel._bluetooth.devices.length + " paired" : "On")
                              : "Off"
                    checked: ccPanel._bluetooth.enabled
                    onToggled: ccPanel._cmd({ cmd: "action", action: "toggle_bluetooth" })
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
