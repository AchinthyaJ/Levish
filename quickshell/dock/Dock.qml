// Floating application dock. One layer-shell surface per target monitor, anchored to the
// bottom edge on the Top layer. It is non-exclusive (exclusiveZone 0), so it reserves no
// space and never displaces tiled windows; it floats above them. Only the glass body and tooltips
// take pointer input (the input mask), so transparent margins around it stay click-through.
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../common/Theme.js" as Theme

PanelWindow {
    id: win
    required property var dockState    // DockModel
    required property var dockConfig   // DockSettings

    readonly property real pad: Theme.dockShadowPad
    readonly property real tipRoom: Theme.dockTipRoom
    readonly property bool autoHide: dockConfig.autoHide
    // Visible by default. If auto-hide is enabled, manages reveal state.
    property bool shown: !autoHide

    visible: dockConfig.enabled !== false
    anchors { bottom: true }
    margins { bottom: 0 }
    readonly property real bottomGap: Math.max(pad, dockConfig.bottomMargin)
    implicitWidth: body.width + pad * 2
    implicitHeight: tipRoom + body.height + bottomGap
    exclusiveZone: 0
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "levish-dock"
    WlrLayershell.layer: WlrLayer.Top

    onAutoHideChanged: shown = !autoHide

    // Input mask: covers the interaction area so clicks outside pass to windows below
    mask: Region { item: win.autoHide ? (win.shown ? interactionArea : zone) : interactionArea }

    Item {
        id: interactionArea
        anchors.fill: parent
    }

    // Auto-hide reveal zone: a comfortable 16 px strip at the screen bottom when hidden,
    // and the full dock area when shown so moving to tooltips never triggers hiding.
    Item {
        id: zone
        x: 0
        width: win.width
        y: win.shown ? 0 : win.height - 16
        height: win.height - y

        HoverHandler {
            id: reveal
            enabled: win.autoHide
            onHoveredChanged: {
                if (hovered) {
                    hideDelay.stop()
                    win.shown = true
                } else {
                    hideDelay.restart()
                }
            }
        }
    }

    Timer {
        id: hideDelay
        interval: 600
        onTriggered: if (!reveal.hovered && win.autoHide) win.shown = false
    }

    Item {
        id: body
        x: win.pad
        y: win.autoHide && !win.shown ? win.height : win.tipRoom
        width: row.width + Theme.dockInnerPad * 2
        height: row.height + Theme.dockInnerPad * 2
        Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        // Subtle multi-layer glass shadow
        Repeater {
            model: [1, 3, 5]
            Rectangle {
                required property int modelData
                x: -modelData
                y: 2 - modelData
                width: body.width + modelData * 2
                height: body.height + modelData * 2
                radius: Theme.dockRadius + modelData
                color: Theme.dockShadow
            }
        }

        // Neutral translucent glass container with hairline border
        Rectangle {
            anchors.fill: parent
            radius: Theme.dockRadius
            color: win.dockConfig.glassColor ? win.dockConfig.glassColor : Theme.dockGlass
            border.color: Theme.dockEdge
            border.width: 1
            Behavior on color { ColorAnimation { duration: 180 } }
        }

        Row {
            id: row
            x: Theme.dockInnerPad
            y: Theme.dockInnerPad
            spacing: 4

            LauncherButton {
                dockState: win.dockState
                iconSize: win.dockConfig.iconSize
            }

            Rectangle {
                visible: win.dockConfig.pinned.length > 0
                width: 1
                height: win.dockConfig.iconSize * 0.5
                y: (row.height - height) / 2
                color: Theme.dockRule
            }

            Repeater {
                model: win.dockConfig.pinned
                delegate: DockItem {
                    required property string modelData
                    dockState: win.dockState
                    iconSize: win.dockConfig.iconSize
                    entry: win.dockState.entryFor(modelData)
                    label: entry ? entry.name : modelData
                    matchClass: ""
                    visible: entry !== null
                }
            }

            Rectangle {
                visible: win.dockState.running.length > 0
                width: 1
                height: win.dockConfig.iconSize * 0.5
                y: (row.height - height) / 2
                color: Theme.dockRule
            }

            Repeater {
                model: win.dockState.running
                delegate: DockItem {
                    required property string modelData
                    dockState: win.dockState
                    iconSize: win.dockConfig.iconSize
                    matchClass: modelData
                    entry: win.dockState.entryForClass(modelData)
                    label: entry ? entry.name : modelData
                }
            }
        }
    }
}
