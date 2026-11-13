// Floating island top bar. Left: performance. Center: workspaces and window.
// Right: clock, status, tray, power. All islands share one y-axis.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import "../common" as C
import "../common/Theme.js" as Theme
import "." as B

PanelWindow {
    id: bar
    required property var store
    signal perfHovered(bool v)
    signal statusClicked()   // emitted when the status island is tapped
    property bool perfOpen: false     // performance drop-down is showing
    property bool statusOpen: false   // control centre is showing

    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight
    color: "transparent"
    // Reserve the bar's height so windows are pushed below it.
    exclusiveZone: Theme.barHeight
    WlrLayershell.namespace: "levish-bar"
    WlrLayershell.layer: WlrLayer.Top

    // Island geometry, read by the drop-down panels so they grow out of the right island.
    //   perfLeft / perfWidth: performance island, measured from the screen's left edge.
    //   statusRight / statusWidth: status island, measured from the screen's right edge.
    readonly property real perfLeft: 12 + perf.x
    readonly property real perfWidth: perf.width
    readonly property real statusRight: bar.width - 12 - (statusIsland.x + statusIsland.width)
    readonly property real statusWidth: statusIsland.width

    RowLayout {
        anchors { fill: parent; leftMargin: 12; rightMargin: 12; topMargin: Theme.barEdge }
        spacing: Theme.barGap

        // ── Performance (hover opens the panel) ───────────────────
        Island {
            id: perf
            hoverable: true
            lift: false
            flatBottom: bar.perfOpen
            Layout.preferredHeight: Theme.barHeight
            onEntered: bar.perfHovered(true)
            onExited: bar.perfHovered(false)
            // Every metric is one 18px-tall cell on the same centre line.
            // CPU uses an icon; RAM sits in a labelled tag; GPU is just the word.
            Row {
                spacing: 12
                anchors.verticalCenter: parent.verticalCenter
                height: 18

                Row {
                    spacing: 6; height: 18
                    C.Icon { kind: "cpu"; tint: Theme.cpu; width: 18; height: 18 }
                    Text { text: Math.round(bar.store.metrics.cpu_percent) + "%"; color: Theme.cpu; height: 18; verticalAlignment: Text.AlignVCenter; font.pixelSize: 14; font.family: "JetBrains Mono" }
                }
                Row {
                    spacing: 6; height: 18
                    Rectangle {
                        width: ramTag.implicitWidth + 10; height: 16; radius: 5
                        anchors.verticalCenter: parent.verticalCenter
                        color: "transparent"
                        border.color: Theme.memory; border.width: 1
                        Text {
                            id: ramTag
                            anchors.centerIn: parent
                            text: "RAM"; color: Theme.memory
                            font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 0.6
                        }
                    }
                    Text { text: Math.round(bar.store.metrics.ram_percent) + "%"; color: Theme.memory; height: 18; verticalAlignment: Text.AlignVCenter; font.pixelSize: 14; font.family: "JetBrains Mono" }
                }
                Row {
                    spacing: 6; height: 18
                    visible: bar.store.metrics.gpu_percent !== null
                    Text { text: "GPU"; color: Theme.gpu; height: 18; verticalAlignment: Text.AlignVCenter; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 0.6 }
                    Text { text: Math.round(bar.store.metrics.gpu_percent || 0) + "%"; color: Theme.gpu; height: 18; verticalAlignment: Text.AlignVCenter; font.pixelSize: 14; font.family: "JetBrains Mono" }
                }
                Row {
                    spacing: 4; height: 18
                    visible: bar.store.metrics.cpu_temp !== null
                    C.Icon { kind: "thermo"; tint: Theme.muted; width: 18; height: 18 }
                    Text { text: Math.round(bar.store.metrics.cpu_temp || 0) + "°"; color: Theme.muted; height: 18; verticalAlignment: Text.AlignVCenter; font.pixelSize: 14; font.family: "JetBrains Mono" }
                }
            }
        }

        // ── Workspaces ────────────────────────────────────────────
        Island {
            Layout.preferredHeight: Theme.barHeight
            Row {
                spacing: 10
                anchors.verticalCenter: parent.verticalCenter
                Repeater {
                    model: Hyprland.workspaces
                    Rectangle {
                        required property var modelData
                        width: modelData.focused ? 32 : 12
                        height: 12
                        radius: 6
                        color: modelData.focused ? Theme.accent : (modelData.active ? "#ccffffff" : "#44ffffff")
                        Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
                        Behavior on color { ColorAnimation { duration: 220 } }
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + modelData.id + " })")
                        }
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }

        // ── Active window (center) ────────────────────────────────
        Island {
            Layout.preferredHeight: Theme.barHeight
            Layout.maximumWidth: 280
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: bar.store.activeTitle || bar.store.activeClass || "Desktop"
                color: Theme.text
                font.pixelSize: 13
                font.weight: Font.Medium
                elide: Text.ElideRight
                width: Math.min(implicitWidth, 240)
            }
        }

        Item { Layout.fillWidth: true }

        // ── Clock ─────────────────────────────────────────────────
        Island {
            Layout.preferredHeight: Theme.barHeight
            Clock { anchors.verticalCenter: parent.verticalCenter }
        }

        // ── Status: network · volume · battery  (click → Control Center) ─
        Island {
            id: statusIsland
            Layout.preferredHeight: Theme.barHeight
            hoverable: true
            lift: false
            flatBottom: bar.statusOpen
            onClicked: bar.statusClicked()

            // All three items share one 18px row so their icons sit on the same centre line.
            Row {
                spacing: 14
                height: 18
                anchors.verticalCenter: parent.verticalCenter

                // Network
                C.Icon {
                    width: 18; height: 18
                    kind: bar.store.network.connected ? "wifi" : "wifiOff"
                    tint: bar.store.network.connected ? Theme.network : Theme.muted
                }

                // Volume: icon + slider
                Row {
                    spacing: 8
                    height: 18
                    C.Icon {
                        width: 18; height: 18
                        kind: bar.store.audio.muted ? "mute" : (bar.store.audio.volume > 33 ? "volume" : "volLow")
                        tint: bar.store.audio.muted ? Theme.muted : Theme.text
                    }
                    Item {
                        width: 46; height: 18
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width; height: 4; radius: 2; color: "#22ffffff"
                            Rectangle {
                                width: parent.width * Math.min(1, bar.store.audio.volume / 100)
                                height: parent.height; radius: 2
                                color: bar.store.audio.muted ? Theme.muted : Theme.storage
                                Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                            }
                        }
                    }
                }

                // Battery: phone-style icon + percentage
                Row {
                    spacing: 6
                    height: 18
                    BatteryIcon { level: bar.store.battery.percent; charging: bar.store.battery.charging }
                    Text {
                        text: bar.store.battery.percent + "%"
                        color: Theme.text
                        height: 18; verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 12; font.family: "JetBrains Mono"
                    }
                }
            }
        }

        // ── Tray ──────────────────────────────────────────────────
        Island {
            Layout.preferredHeight: Theme.barHeight
            visible: SystemTray.items.values.length > 0
            Row {
                spacing: 10
                anchors.verticalCenter: parent.verticalCenter
                Repeater {
                    model: SystemTray.items
                    Image {
                        required property var modelData
                        width: 18; height: 18
                        source: modelData.icon
                        sourceSize.width: 18; sourceSize.height: 18
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: modelData.activate() }
                    }
                }
            }
        }

        // ── Power ─────────────────────────────────────────────────
        Island {
            Layout.preferredHeight: Theme.barHeight
            PowerButton { anchors.verticalCenter: parent.verticalCenter }
        }
    }
}
