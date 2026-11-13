// Floating application dock. One layer-shell surface per target monitor, anchored to the
// bottom edge on the Overlay layer. It is non-exclusive (exclusiveZone 0), so it reserves no
// space and never displaces tiled windows; it floats above them. Only the glass body takes
// pointer input (the input mask), so the transparent margins around it stay click-through.
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
    // Auto-hide only: true while the pointer is revealing the dock.
    property bool shown: !autoHide

    anchors { bottom: true }
    margins { bottom: 0 }
    // The window stays on the screen edge so the auto-hide strip is reachable. The gap
    // above the screen edge (configured margin, at least the shadow pad) is inside the window.
    readonly property real bottomGap: Math.max(pad, dockConfig.bottomMargin)
    implicitWidth: body.width + pad * 2
    implicitHeight: tipRoom + body.height + bottomGap
    exclusiveZone: 0
    // Sit on the true screen edge, ignoring other shells' exclusive zones (e.g. a border strip).
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "levish-dock"
    WlrLayershell.layer: WlrLayer.Overlay

    onAutoHideChanged: shown = !autoHide

    // Input is limited to the glass (or, with auto-hide, to the reveal zone), so the
    // transparent headroom and margins never block clicks on windows underneath.
    mask: Region { item: win.autoHide ? zone : body }

    // Auto-hide reveal zone: a 3 px strip at the bottom edge while hidden, and the whole
    // lower part of the window while shown, so moving the pointer onto the glass keeps it open.
    Item {
        id: zone
        x: 0
        width: win.width
        y: win.shown ? win.tipRoom : win.height - 3
        height: win.height - y

        // HoverHandler is passive: it sees the pointer even when a child icon's MouseArea
        // is under it, so hovering a cell never looks like leaving the dock.
        HoverHandler {
            id: reveal
            enabled: win.autoHide
            onHoveredChanged: {
                if (hovered) { hideDelay.stop(); win.shown = true }
                else hideDelay.restart()
            }
        }
    }
    Timer {
        id: hideDelay
        interval: 450
        onTriggered: if (!reveal.hovered) win.shown = false
    }

    Item {
        id: body
        x: win.pad
        y: win.autoHide && !win.shown ? win.height : win.tipRoom
        width: row.width + Theme.dockInnerPad * 2
        height: row.height + Theme.dockInnerPad * 2
        Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

        // Very subtle shadow: three faint, growing silhouettes sitting just below the glass.
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

        // Neutral translucent glass with a hairline border.
        Rectangle {
            anchors.fill: parent
            radius: Theme.dockRadius
            color: Theme.dockGlass
            border.color: Theme.dockEdge
            border.width: 1
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
