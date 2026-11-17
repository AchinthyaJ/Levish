import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../components"
import "../../common/Theme.js" as Theme
import "../../common" as Pal

// Sound: output and input devices, and a mixer for each application playing audio.
// Every control calls AudioService, which talks to PipeWire directly.
Flickable {
    id: page
    property var themeStore
    property var audio                  // AudioService
    property string pageId: ""
    ScrollBar.vertical: PageScrollBar { accent: page.accent }
    property string keywords: "sound audio volume output input microphone speaker headphones mute application stream pipewire"
    readonly property var resetPaths: []
    readonly property color accent: Pal.Palette.accent

    contentHeight: col.implicitHeight + 40
    clip: true

    ColumnLayout {
        id: col
        x: 24; y: 20
        width: page.width - 48
        spacing: 16

        SettingsCard {
            title: "Status"
            SettingsRow {
                label: "PipeWire"
                hint: "The audio server that every device and application uses."
                Text {
                    text: !page.audio ? "Not connected" : (page.audio.ready ? "Connected" : "Starting…")
                    color: page.audio && page.audio.ready ? Pal.Palette.ok : Pal.Palette.warning
                    font.pixelSize: Theme.fs(12)
                }
            }
            SettingsRow {
                label: "Default output"
                hint: page.audio && page.audio.defaultOutput ? "" : "Nothing selected yet."
                Text {
                    text: page.audio && page.audio.defaultOutput ? page.audio.label(page.audio.defaultOutput) : "None"
                    color: Pal.Palette.text
                    font.pixelSize: Theme.fs(12)
                    elide: Text.ElideRight
                    Layout.maximumWidth: 260
                }
            }
        }

        // ── Output devices ──────────────────────────────────────────────
        SettingsCard {
            title: "Output devices"
            Text {
                visible: page.audio && page.audio.outputs.length === 0
                text: "No output devices. Connect speakers or headphones, or check that PipeWire is running."
                color: Pal.Palette.muted
                font.pixelSize: Theme.fs(12)
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
            Repeater {
                model: page.audio ? page.audio.outputs : []
                delegate: DeviceRow {
                    required property var modelData
                    node: modelData
                    isDefault: page.audio && page.audio.defaultOutput === modelData
                    onMakeDefault: page.audio.setDefaultOutput(modelData)
                }
            }
        }

        // ── Input devices ───────────────────────────────────────────────
        SettingsCard {
            title: "Input devices"
            Text {
                visible: page.audio && page.audio.inputs.length === 0
                text: "No microphones found."
                color: Pal.Palette.muted
                font.pixelSize: Theme.fs(12)
                Layout.fillWidth: true
            }
            Repeater {
                model: page.audio ? page.audio.inputs : []
                delegate: DeviceRow {
                    required property var modelData
                    node: modelData
                    isDefault: page.audio && page.audio.defaultInput === modelData
                    onMakeDefault: page.audio.setDefaultInput(modelData)
                }
            }
        }

        // ── Application mixer ───────────────────────────────────────────
        SettingsCard {
            title: "Applications"
            Text {
                visible: page.audio && page.audio.streams.length === 0
                text: "Nothing is playing. Applications appear here while they play audio."
                color: Pal.Palette.muted
                font.pixelSize: Theme.fs(12)
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
            Repeater {
                model: page.audio ? page.audio.streams : []
                delegate: Rectangle {
                    id: streamRow
                    required property var modelData
                    readonly property var node: modelData
                    readonly property string route: page.audio ? page.audio.routeOf(node) : ""
                    Layout.fillWidth: true
                    implicitHeight: streamCol.implicitHeight + 20
                    radius: 9
                    color: Pal.Palette.controlFill
                    border.color: Pal.Palette.controlEdge
                    border.width: 1

                    ColumnLayout {
                        id: streamCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            Image {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                source: Quickshell.iconPath(page.audio.appIcon(streamRow.node), "audio-x-generic")
                                sourceSize: Qt.size(24, 24)
                                fillMode: Image.PreserveAspectFit
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    text: page.audio.label(streamRow.node)
                                    color: Pal.Palette.text
                                    font.pixelSize: Theme.fs(13)
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: !streamRow.node.audio ? "Volume unavailable" : (streamRow.node.audio.muted ? "Muted" : "Playing")
                                    color: Pal.Palette.muted
                                    font.pixelSize: Theme.fs(11)
                                }
                            }
                            SettingsSlider {
                                Layout.preferredWidth: 180
                                Layout.bottomMargin: 14
                                from: 0; to: 100; step: 1; suffix: "%"; accent: page.accent
                                enabled: !!streamRow.node.audio
                                value: streamRow.node.audio ? Math.round(streamRow.node.audio.volume * 100) : 0
                                onCommitted: (v) => page.audio.setVolume(streamRow.node, v / 100)
                            }
                            SettingsButton {
                                text: streamRow.node.audio && streamRow.node.audio.muted ? "Unmute" : "Mute"
                                enabled: !!streamRow.node.audio
                                onClicked: page.audio.setMuted(streamRow.node, !streamRow.node.audio.muted)
                            }
                        }

                        // Where this application's sound goes.
                        Flow {
                            Layout.fillWidth: true
                            spacing: 6
                            Text {
                                text: "Output:"
                                color: Pal.Palette.muted
                                font.pixelSize: Theme.fs(11)
                                height: 24
                                verticalAlignment: Text.AlignVCenter
                            }
                            Repeater {
                                model: [{ name: "", label: "Default" }].concat(page.audio ? page.audio.outputs.map(o => ({ name: o.name, label: page.audio.label(o) })) : [])
                                delegate: Rectangle {
                                    id: chip
                                    required property var modelData
                                    readonly property bool chosen: streamRow.route === modelData.name
                                    height: 24
                                    width: Math.max(64, chipText.implicitWidth + 16)
                                    radius: 7
                                    color: chosen ? Qt.rgba(page.accent.r, page.accent.g, page.accent.b, 0.22) : Pal.Palette.controlFill
                                    border.color: chosen ? page.accent : Pal.Palette.controlEdge
                                    border.width: 1
                                    Text {
                                        id: chipText
                                        anchors.centerIn: parent
                                        text: chip.modelData.label
                                        color: chip.chosen ? Pal.Palette.text : Pal.Palette.muted
                                        font.pixelSize: Theme.fs(11)
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            const target = chip.modelData.name === "" ? null
                                                : page.audio.outputs.find(o => o.name === chip.modelData.name)
                                            page.audio.routeStream(streamRow.node, target)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Text {
                visible: page.audio && page.audio.routeError !== ""
                text: page.audio ? page.audio.routeError : ""
                color: Pal.Palette.danger
                font.pixelSize: Theme.fs(11)
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
        }
    }

    // One device: name, default badge, volume and mute.
    component DeviceRow: Rectangle {
        id: dev
        property var node
        property bool isDefault: false
        signal makeDefault()
        Layout.fillWidth: true
        implicitHeight: 84
        radius: 9
        color: isDefault ? Qt.rgba(page.accent.r, page.accent.g, page.accent.b, 0.1) : Pal.Palette.controlFill
        border.color: isDefault ? page.accent : Pal.Palette.controlEdge
        border.width: 1

        ColumnLayout {
            anchors { fill: parent; leftMargin: 12; rightMargin: 12; topMargin: 8; bottomMargin: 8 }
            spacing: 6
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Text {
                    text: page.audio.label(dev.node)
                    color: Pal.Palette.text
                    font.pixelSize: Theme.fs(13)
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    visible: dev.isDefault
                    text: "Default"
                    color: page.accent
                    font.pixelSize: Theme.fs(11)
                    font.weight: Font.DemiBold
                }
                SettingsButton {
                    visible: !dev.isDefault
                    text: "Use as default"
                    onClicked: dev.makeDefault()
                }
            }
            // The PipeWire node name tells two devices of the same model apart.
            Text {
                text: dev.node.name
                color: Pal.Palette.muted
                font.pixelSize: Theme.fs(10)
                elide: Text.ElideMiddle
                Layout.fillWidth: true
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                SettingsSlider {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 14
                    from: 0; to: 100; step: 1; suffix: "%"; accent: page.accent
                    value: Math.round(dev.node.audio.volume * 100)
                    onCommitted: (v) => page.audio.setVolume(dev.node, v / 100)
                }
                SettingsButton {
                    text: dev.node.audio.muted ? "Unmute" : "Mute"
                    onClicked: page.audio.setMuted(dev.node, !dev.node.audio.muted)
                }
            }
        }
    }
}
