import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import Quickshell.Networking
import "../components"
import "../../common/Theme.js" as Theme
import "../../common" as Pal

// Network: Wi-Fi on and off, the Wi-Fi networks in range, connect, disconnect, forget, and
// the state of each network device. Uses Quickshell's native NetworkManager service.
Flickable {
    id: page
    property var themeStore
    property string pageId: ""
    ScrollBar.vertical: PageScrollBar { accent: page.accent }
    property string keywords: "network wifi wi-fi wireless ethernet connection connect disconnect forget password signal dns ip vpn"
    readonly property var resetPaths: []
    readonly property color accent: Pal.Palette.accent

    readonly property var devices: Networking.devices ? Networking.devices.values : []
    readonly property var wifiDevice: {
        for (const d of devices) if (d.type === DeviceType.Wifi) return d
        return null
    }
    readonly property var networks: wifiDevice && wifiDevice.networks ? wifiDevice.networks.values : []
    property var selected: null

    // Address, gateway and DNS of the Wi-Fi interface, from NetworkManager in terse form (-t), which
    // is not provided by the native network service.
    property var conn: ({})
    property string connState: "idle"      // idle | loading | ok | error
    function refreshConnection() {
        if (!wifiDevice) { conn = ({}); connState = "idle"; return }
        connState = "loading"
        connProc.running = false
        connProc.command = ["nmcli", "-t", "-f", "IP4.ADDRESS,IP4.GATEWAY,IP4.DNS", "device", "show", wifiDevice.name]
        connProc.running = true
    }
    Process {
        id: connProc
        stdout: StdioCollector { id: connOut }
        onExited: (code) => {
            if (code !== 0) { page.connState = "error"; return }
            const d = {}
            const dns = []
            for (const line of connOut.text.split("\n")) {
                const i = line.indexOf(":")
                if (i < 0) continue
                const key = line.substring(0, i)
                const value = line.substring(i + 1).trim()
                if (!value) continue
                if (key.indexOf("IP4.ADDRESS") === 0 && !d.address) d.address = value
                else if (key.indexOf("IP4.GATEWAY") === 0) d.gateway = value
                else if (key.indexOf("IP4.DNS") === 0) dns.push(value)
            }
            if (dns.length) d.dns = dns.join(", ")
            page.conn = d
            page.connState = "ok"
        }
    }
    // Deferred: changing state while a binding is being evaluated creates a binding loop.
    onWifiDeviceChanged: Qt.callLater(page.refreshConnection)
    Connections {
        target: page.wifiDevice
        function onConnectedChanged() { Qt.callLater(page.refreshConnection) }
    }
    Component.onCompleted: Qt.callLater(page.refreshConnection)

    function bars(n) { return Math.max(0, Math.min(4, Math.round(n * 4))) }

    contentHeight: col.implicitHeight + 40
    clip: true

    ColumnLayout {
        id: col
        x: 24; y: 20
        width: page.width - 48
        spacing: 16

        SettingsCard {
            title: "Wi-Fi"
            SettingsRow {
                label: "Wi-Fi"
                hint: Networking.wifiHardwareEnabled ? "Turn wireless networking on or off." : "The Wi-Fi hardware is switched off."
                SettingsToggle { accent: page.accent; checked: Networking.wifiEnabled
                    enabled: Networking.wifiHardwareEnabled
                    onToggled: (v) => Networking.wifiEnabled = v }
            }
            SettingsRow {
                label: "Scan for networks"
                hint: "Finds the Wi-Fi networks nearby. Turn it off to save power."
                SettingsToggle { accent: page.accent; checked: page.wifiDevice ? page.wifiDevice.scannerEnabled : false
                    enabled: !!page.wifiDevice && Networking.wifiEnabled
                    onToggled: (v) => page.wifiDevice.scannerEnabled = v }
            }
            SettingsRow {
                label: "Scan for networks"
                hint: "Finds the Wi-Fi networks nearby. Turn it off to save power."
                SettingsToggle { accent: page.accent; checked: page.wifiDevice ? page.wifiDevice.scannerEnabled : false
                    enabled: !!page.wifiDevice && Networking.wifiEnabled
                    onToggled: (v) => page.wifiDevice.scannerEnabled = v }
            }
            SettingsRow {
                label: "Connectivity"
                hint: "Whether this machine can reach the internet."
                Text {
                    text: Networking.canCheckConnectivity ? String(NetworkConnectivity.toString(Networking.connectivity)) : "Not checked"
                    color: Pal.Palette.text
                    font.pixelSize: Theme.fs(12)
                }
            }
            SettingsRow {
                label: "Backend"
                Text {
                    text: String(NetworkBackendType.toString(Networking.backend))
                    color: Pal.Palette.muted
                    font.pixelSize: Theme.fs(12)
                }
            }
        }

        SettingsCard {
            title: "Networks in range"
            Text {
                visible: !page.wifiDevice
                text: Networking.wifiEnabled ? "No Wi-Fi device found." : "Turn Wi-Fi on to see networks."
                color: Pal.Palette.muted
                font.pixelSize: Theme.fs(12)
                Layout.fillWidth: true
            }
            Text {
                visible: page.wifiDevice && page.networks.length === 0
                text: "No networks found yet. They appear here after a scan."
                color: Pal.Palette.muted
                font.pixelSize: Theme.fs(12)
                Layout.fillWidth: true
            }
            Repeater {
                model: page.networks
                delegate: Rectangle {
                    id: netRow
                    required property var modelData
                    readonly property var net: modelData
                    Layout.fillWidth: true
                    implicitHeight: 52
                    radius: 9
                    color: net.connected ? Qt.rgba(page.accent.r, page.accent.g, page.accent.b, 0.1) : Pal.Palette.controlFill
                    border.color: page.selected === net ? page.accent : Pal.Palette.controlEdge
                    border.width: 1

                    MouseArea {
                        anchors.fill: parent
                        onClicked: page.selected = netRow.net
                    }
                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        spacing: 12
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                text: netRow.net.name || "(hidden network)"
                                color: Pal.Palette.text
                                font.pixelSize: Theme.fs(13)
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: (netRow.net.connected ? "Connected · " : (netRow.net.known ? "Saved · " : ""))
                                      + String(WifiSecurityType.toString(netRow.net.security))
                                color: Pal.Palette.muted
                                font.pixelSize: Theme.fs(11)
                            }
                        }
                        Text {
                            text: page.bars(netRow.net.signalStrength) + "/4 signal"
                            color: Pal.Palette.muted
                            font.pixelSize: Theme.fs(11)
                        }
                        SettingsButton {
                            visible: !netRow.net.connected
                            text: "Connect"
                            onClicked: netRow.net.connect()
                        }
                        SettingsButton {
                            visible: netRow.net.connected
                            text: "Disconnect"
                            onClicked: netRow.net.disconnect()
                        }
                        SettingsButton {
                            visible: netRow.net.known
                            danger: true
                            text: "Forget"
                            onClicked: netRow.net.forget()
                        }
                    }
                }
            }
            Text {
                text: "Networks that need a password are connected from the Control Centre, which asks for it."
                color: Pal.Palette.muted
                font.pixelSize: Theme.fs(11)
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
        }

        SettingsCard {
            title: "Details"
            visible: page.selected !== null
            SettingsRow { label: "Name"; Text { text: page.selected ? page.selected.name : ""; color: Pal.Palette.text; font.pixelSize: Theme.fs(12) } }
            SettingsRow { label: "Security"; Text { text: page.selected ? String(WifiSecurityType.toString(page.selected.security)) : ""; color: Pal.Palette.text; font.pixelSize: Theme.fs(12) } }
            SettingsRow { label: "Saved"; Text { text: page.selected && page.selected.known ? "Yes" : "No"; color: Pal.Palette.text; font.pixelSize: Theme.fs(12) } }
            SettingsRow { label: "Signal"; Text { text: page.selected ? Math.round(page.selected.signalStrength * 100) + "%" : ""; color: Pal.Palette.text; font.pixelSize: Theme.fs(12) } }
        }

        SettingsCard {
            title: "Connection"
            SettingsRow {
                label: "Interface"
                hint: page.wifiDevice ? "" : "No Wi-Fi device."
                Text { text: page.wifiDevice ? page.wifiDevice.name : "-"; color: Pal.Palette.text; font.pixelSize: Theme.fs(12) }
            }
            SettingsRow {
                label: "IP address"
                Text {
                    text: page.connState === "loading" ? "Reading…"
                        : page.connState === "error" ? "Could not read"
                        : (page.conn.address || (page.wifiDevice && page.wifiDevice.connected ? "None" : "Not connected"))
                    color: Pal.Palette.text
                    font.pixelSize: Theme.fs(12)
                }
            }
            SettingsRow {
                label: "Gateway"
                Text { text: page.conn.gateway || "-"; color: Pal.Palette.text; font.pixelSize: Theme.fs(12) }
            }
            SettingsRow {
                label: "DNS servers"
                Text { text: page.conn.dns || "-"; color: Pal.Palette.text; font.pixelSize: Theme.fs(12) }
            }
            SettingsRow {
                label: "Refresh"
                hint: "Read the address details again."
                SettingsButton { text: "Refresh"; onClicked: page.refreshConnection() }
            }
        }

        SettingsCard {
            title: "Devices"
            Text {
                visible: page.devices.length === 0
                text: "No network devices are reported."
                color: Pal.Palette.muted
                font.pixelSize: Theme.fs(12)
            }
            Repeater {
                model: page.devices
                delegate: SettingsRow {
                    required property var modelData
                    label: modelData.name
                    hint: String(DeviceType.toString(modelData.type)) + " · " + String(ConnectionState.toString(modelData.state))
                    SettingsButton {
                        visible: modelData.connected
                        text: "Disconnect"
                        onClicked: modelData.disconnect()
                    }
                }
            }
        }
    }
}
