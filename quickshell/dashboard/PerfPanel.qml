// Performance dashboard: grows out of the performance island on hover.
// Top: CPU · GPU.  Bottom: Storage · Network · Memory.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../common" as C
import "../common/Theme.js" as Theme
import "../common" as Pal

PanelWindow {
    id: panel
    required property var store
    property bool open: false
    property bool hovered: hover.containsMouse
    // Geometry of the island this panel drops from (screen pixels).
    property real anchorLeft: 0
    property real anchorWidth: 200
    // Floating Islands: a separate rounded panel below the bar, not joined to it.
    property bool floating: false
    property real barHeight: 0

    readonly property real flt: floating ? 0 : Theme.fillet
    readonly property real bodyW: 760

    anchors { top: true; left: true }
    // Margins are measured from the bar's bottom edge (its exclusive zone), so one
    // fillet above that edge puts the curved shoulders beside the island.
    // Start the window one fillet above the bar's bottom edge, so the curved
    // shoulders sit beside the island's bottom and the wall meets it directly.
    // The top margin is measured from the bar's exclusive zone, so the bar's height is already included.
    margins { top: floating ? 10 : 0; left: anchorLeft - flt }
    implicitWidth: bodyW + 2 * flt
    implicitHeight: col.implicitHeight + 40 + flt
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.namespace: "levish-panel"
    WlrLayershell.layer: WlrLayer.Top
    visible: open || body.opacity > 0.01

    Item {
        id: body
        anchors.fill: parent
        opacity: panel.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.dur(240); easing.type: Easing.OutCubic } }

        // Grow from the island: start narrow (island width) and short, scale up to full size.
        transform: Scale {
            origin.x: panel.flt + panel.anchorWidth / 2
            origin.y: 0
            xScale: panel.open ? 1 : Math.max(0.2, panel.anchorWidth / (panel.bodyW + 2 * panel.flt))
            yScale: panel.open ? 1 : 0.3
            Behavior on xScale { NumberAnimation { duration: Theme.dur(320); easing.type: Easing.OutCubic } }
            Behavior on yScale { NumberAnimation { duration: Theme.dur(320); easing.type: Easing.OutCubic } }
        }

        // Floating: a rounded glass card. Unified: the shape that flows out of the bar.
        Rectangle {
            visible: panel.floating
            anchors.fill: parent
            radius: 22
            color: Pal.Palette.glass
            border.color: Pal.Palette.glassEdge
            border.width: 1
        }
        C.DropShape {
            visible: !panel.floating
            anchors.fill: parent
            fillet: panel.flt
            radius: Theme.dropRadius
            fillColor: Pal.Palette.glass
            edgeColor: Pal.Palette.glassEdge
        }

        // The whole panel is one hover target, so moving within it never closes it.
        MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true; propagateComposedEvents: true }

        ColumnLayout {
            id: col
            x: panel.flt + 14; y: panel.flt + 16
            width: panel.bodyW - 28
            spacing: 8

            // ── Top row ────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                StatCard {
                    Layout.fillWidth: true
                    kind: "cpu"; title: "CPU"; subtitle: panel.store.cpuModel
                    tint: Pal.Palette.accent
                    value: panel.store.metrics.cpu_percent
                    temp: panel.store.metrics.cpu_temp
                }
                StatCard {
                    Layout.fillWidth: true
                    label: "GPU"; title: "GPU"
                    subtitle: panel.store.metrics.gpu_percent === null ? "No GPU data" : "Graphics"
                    tint: Pal.Palette.accent
                    value: panel.store.metrics.gpu_percent === null ? 0 : panel.store.metrics.gpu_percent
                    temp: panel.store.metrics.gpu_temp
                }
            }

            // ── Bottom row ─────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Storage
                Card {
                    Layout.preferredWidth: 206
                    Layout.preferredHeight: 150
                    RowLayout {
                        anchors.fill: parent
                        spacing: 10
                        C.Ring {
                            Layout.preferredWidth: 84; Layout.preferredHeight: 84
                            value: parseFloat(panel.store.disk) || 0
                            arcColor: Pal.Palette.accent
                            label: Math.round(parseFloat(panel.store.disk) || 0) + "%"
                            caption: "Used"
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            Text { text: "Storage"; color: Pal.Palette.text; font.pixelSize: Theme.fs(12); font.weight: Font.DemiBold }
                            Text { text: panel.store.diskText; color: Pal.Palette.muted; font.pixelSize: Theme.fs(10); wrapMode: Text.WordWrap; Layout.fillWidth: true }
                        }
                    }
                }

                // Network
                Card {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 150
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 4
                        RowLayout {
                            spacing: 6
                            C.Icon { kind: "down"; tint: Pal.Palette.accent; width: 14; height: 14 }
                            Text { text: "Network"; color: Pal.Palette.accent; font.pixelSize: Theme.fs(12); font.weight: Font.DemiBold }
                        }
                        NetGraph {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            value: panel.store.metrics.net_down_mbps
                        }
                        NetRow { label: "Download"; value: panel.store.metrics.net_down_mbps.toFixed(2) + " MB/s" }
                        NetRow { label: "Upload";   value: panel.store.metrics.net_up_mbps.toFixed(2) + " MB/s" }
                    }
                }

                // Memory
                Card {
                    Layout.preferredWidth: 170
                    Layout.preferredHeight: 150
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 4
                        RowLayout {
                            spacing: 6
                            Rectangle {
                                width: ramTag.implicitWidth + 10; height: 16; radius: 5
                                color: "transparent"
                                border.color: Pal.Palette.accent; border.width: 1
                                Text {
                                    id: ramTag
                                    anchors.centerIn: parent
                                    text: "RAM"; color: Pal.Palette.accent
                                    font.pixelSize: Theme.fs(9); font.weight: Font.Bold; font.letterSpacing: 0.6
                                }
                            }
                            Text { text: "Memory"; color: Pal.Palette.text; font.pixelSize: Theme.fs(12); font.weight: Font.DemiBold }
                        }
                        C.Ring {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 78; Layout.preferredHeight: 78
                            value: panel.store.metrics.ram_percent
                            arcColor: Pal.Palette.accent
                            label: Math.round(panel.store.metrics.ram_percent) + "%"
                            caption: "Used"
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: panel.store.metrics.ram_used_gb.toFixed(1) + " / " + panel.store.metrics.ram_total_gb.toFixed(1) + " GB"
                            color: Pal.Palette.muted; font.pixelSize: Theme.fs(10)
                        }
                    }
                }
            }
        }
    }
}
