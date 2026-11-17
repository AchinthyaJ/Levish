import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Bluetooth
import "../components"
import "../../common/Theme.js" as Theme
import "../../common" as Pal

// Bluetooth: the adapter, paired and nearby devices, connect, disconnect, pair and unpair.
// Uses Quickshell's native BlueZ service, which the Control Centre also uses.
Flickable {
    id: page
    property var themeStore
    property string pageId: ""
    ScrollBar.vertical: PageScrollBar { accent: page.accent }
    property string keywords: "bluetooth pair pairing connect disconnect unpair forget device headphones battery discover scan trusted"
    readonly property var resetPaths: []
    readonly property color accent: Pal.Palette.accent

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var all: adapter && adapter.devices ? adapter.devices.values : []
    readonly property var pairedList: all.filter(d => d.paired || d.connected)
    readonly property var nearbyList: all.filter(d => !d.paired && !d.connected)
    property var selected: null

    contentHeight: col.implicitHeight + 40
    clip: true

    ColumnLayout {
        id: col
        x: 24; y: 20
        width: page.width - 48
        spacing: 16

        SettingsCard {
            title: "Adapter"
            Text {
                visible: !page.adapter
                text: "No Bluetooth adapter is available."
                color: Pal.Palette.muted
                font.pixelSize: Theme.fs(12)
                Layout.fillWidth: true
            }
            SettingsRow {
                visible: !!page.adapter
                label: "Bluetooth"
                hint: page.adapter ? (page.adapter.name || "Adapter") : ""
                SettingsToggle { accent: page.accent; checked: page.adapter ? page.adapter.enabled : false
                    enabled: !!page.adapter
                    onToggled: (v) => page.adapter.enabled = v }
            }
            SettingsRow {
                visible: !!page.adapter
                label: "Discover nearby devices"
                hint: "Scans for devices while this is on. Scanning uses some power."
                SettingsToggle { accent: page.accent; checked: page.adapter ? page.adapter.discovering : false
                    enabled: !!page.adapter && page.adapter.enabled
                    onToggled: (v) => page.adapter.discovering = v }
            }
        }

        SettingsCard {
            title: "Paired and connected"
            visible: !!page.adapter
            Text {
                visible: page.pairedList.length === 0
                text: "No paired devices. Pair one from the list below."
                color: Pal.Palette.muted
                font.pixelSize: Theme.fs(12)
                Layout.fillWidth: true
            }
            Repeater {
                model: page.pairedList
                delegate: DeviceRow {
                    required property var modelData
                    dev: modelData
                    onSelectMe: page.selected = modelData
                }
            }
        }

        SettingsCard {
            title: "Nearby"
            visible: !!page.adapter
            Text {
                visible: page.nearbyList.length === 0
                text: page.adapter && page.adapter.discovering ? "Looking for devices…" : "Turn on discovery to find devices nearby."
                color: Pal.Palette.muted
                font.pixelSize: Theme.fs(12)
                Layout.fillWidth: true
            }
            Repeater {
                model: page.nearbyList
                delegate: DeviceRow {
                    required property var modelData
                    dev: modelData
                    onSelectMe: page.selected = modelData
                }
            }
        }

        SettingsCard {
            title: "Device details"
            visible: page.selected !== null
            SettingsRow { label: "Name"; Text { text: page.selected ? (page.selected.name || page.selected.deviceName) : ""; color: Pal.Palette.text; font.pixelSize: Theme.fs(12) } }
            SettingsRow { label: "Address"; Text { text: page.selected ? page.selected.address : ""; color: Pal.Palette.text; font.pixelSize: Theme.fs(12) } }
            SettingsRow { label: "Paired"; Text { text: page.selected && page.selected.paired ? "Yes" : "No"; color: Pal.Palette.text; font.pixelSize: Theme.fs(12) } }
            SettingsRow { label: "Trusted"; Text { text: page.selected && page.selected.trusted ? "Yes" : "No"; color: Pal.Palette.text; font.pixelSize: Theme.fs(12) } }
            SettingsRow {
                label: "Battery"
                Text {
                    text: page.selected && page.selected.batteryAvailable ? Math.round(page.selected.battery * 100) + "%" : "Not reported"
                    color: Pal.Palette.text
                    font.pixelSize: Theme.fs(12)
                }
            }
        }
    }

    // One device: name, connection state and the actions that apply to it.
    component DeviceRow: Rectangle {
        id: row
        property var dev
        signal selectMe()
        Layout.fillWidth: true
        implicitHeight: 52
        radius: 9
        color: dev.connected ? Qt.rgba(page.accent.r, page.accent.g, page.accent.b, 0.1) : Pal.Palette.controlFill
        border.color: Pal.Palette.controlEdge
        border.width: 1

        MouseArea { anchors.fill: parent; onClicked: row.selectMe() }
        RowLayout {
            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
            spacing: 12
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text {
                    text: row.dev.name || row.dev.deviceName || row.dev.address
                    color: Pal.Palette.text
                    font.pixelSize: Theme.fs(13)
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: (row.dev.connected ? "Connected" : (row.dev.paired ? "Paired" : "Not paired"))
                          + (row.dev.batteryAvailable ? " · " + Math.round(row.dev.battery * 100) + "%" : "")
                    color: Pal.Palette.muted
                    font.pixelSize: Theme.fs(11)
                }
            }
            SettingsButton {
                visible: !row.dev.paired && !row.dev.connected
                text: row.dev.pairing ? "Pairing…" : "Pair"
                enabled: !row.dev.pairing
                onClicked: row.dev.pair()
            }
            SettingsButton {
                visible: row.dev.paired && !row.dev.connected
                text: "Connect"
                onClicked: row.dev.connect()
            }
            SettingsButton {
                visible: row.dev.connected
                text: "Disconnect"
                onClicked: row.dev.disconnect()
            }
            SettingsButton {
                visible: row.dev.paired
                danger: true
                text: "Unpair"
                onClicked: row.dev.forget()
            }
        }
    }
}
