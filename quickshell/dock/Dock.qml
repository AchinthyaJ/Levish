// Floating application dock. One layer-shell surface per target monitor, anchored to the screen
// edge chosen in Settings (bottom by default) on the Top layer. It is non-exclusive
// (exclusiveZone 0), so it reserves no space and never displaces tiled windows; it floats above
// them. Only the glass body and tooltips take pointer input (the input mask), so transparent
// margins around it stay click-through.
//
// Geometry is written once for the bottom edge and mirrored for the others. Along the window the
// layout is: tooltip room first when the dock is at the bottom or right (its inner side is the
// start of the window), otherwise the edge gap comes first.
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../common/Theme.js" as Theme
import "../common" as Pal

PanelWindow {
    id: win
    required property var dockState    // DockModel
    required property var dockConfig   // DockSettings

    readonly property real pad: Theme.dockShadowPad
    readonly property real tipRoom: Theme.dockTipRoom
    readonly property bool autoHide: dockConfig.autoHide
    // Visible by default. If auto-hide is enabled, manages reveal state.
    property bool shown: !autoHide

    readonly property string side: ["top", "bottom", "left", "right"].indexOf(dockConfig.position) >= 0
        ? dockConfig.position : "bottom"
    readonly property bool vertical: side === "left" || side === "right"
    readonly property bool tipFirst: side === "bottom" || side === "right"

    visible: dockConfig.enabled !== false
    anchors {
        top: side === "top"
        bottom: side === "bottom"
        left: side === "left"
        right: side === "right"
    }
    margins { top: 0; bottom: 0; left: 0; right: 0 }
    readonly property real edgeGap: Math.max(pad, dockConfig.bottomMargin)
    // While auto-hidden the surface itself shrinks to the 16 px reveal strip. Resizing the layer
    // surface makes the compositor redraw it, so the dock cannot linger as stale pixels, and no
    // empty transparent area is left reserved at the screen edge.
    readonly property bool hiddenNow: autoHide && !shown
    readonly property real bodyThickness: vertical ? body.width : body.height
    readonly property real fullThickness: tipRoom + bodyThickness + edgeGap
    implicitWidth: vertical ? (hiddenNow ? 16 : fullThickness) : body.width + pad * 2
    implicitHeight: vertical ? body.height + pad * 2 : (hiddenNow ? 16 : fullThickness)
    exclusiveZone: 0
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "levish-dock"
    WlrLayershell.layer: WlrLayer.Top

    // Toggling auto-hide re-runs the reveal check: turning it on hides the dock unless the pointer
    // is already over it, and turning it off keeps the dock shown and cancels any pending hide.
    onAutoHideChanged: {
        if (autoHide) {
            if (stripHover.hovered || bodyHover.hovered) {
                hideDelay.stop()
                shown = true
            } else {
                hideDelay.restart()
            }
        } else {
            hideDelay.stop()
            shown = true
        }
    }

    // Input mask: covers the interaction area so clicks outside pass to windows below
    mask: Region { item: interactionArea }

    Item {
        id: interactionArea
        anchors.fill: parent
    }

    // Auto-hide reveal zone: the whole surface. When hidden the surface is the 16 px strip; when
    // shown it covers the dock area so moving to tooltips never triggers hiding.
    Item {
        id: zone
        anchors.fill: parent

        // Always enabled: disabling a hovered HoverHandler can leave `hovered` stale. hoverChanged()
        // ignores hover while auto-hide is off.
        HoverHandler {
            id: stripHover
            onHoveredChanged: win.hoverChanged(hovered)
        }
    }

    // Hover is tracked on both the strip and the dock body. A HoverHandler is not reliable on a
    // sibling that sits under a hover-enabled MouseArea (the app cells), so the body's own handler
    // is what keeps the dock open while the pointer is over an app.
    //
    // Each handler acts on its own `hovered` value. Do not read a derived binding (such as
    // "either handler is hovered") inside a hover signal: that binding can still hold the previous
    // value there, and a leave event then looks like "still inside", so the dock never hides again.
    // The hide timer reads both handlers directly when it fires, after the event loop has settled.
    function hoverChanged(inside) {
        if (!win.autoHide) return
        if (inside) {
            hideDelay.stop()
            win.shown = true
        } else {
            hideDelay.restart()
        }
    }

    Timer {
        id: hideDelay
        interval: 600
        onTriggered: {
            if (win.autoHide && !stripHover.hovered && !bodyHover.hovered) win.shown = false
        }
    }

    Item {
        id: body
        // Start of the body along the window: after the tooltip room or after the edge gap.
        readonly property real start: win.tipFirst ? win.tipRoom : win.edgeGap
        readonly property real parked: win.fullThickness
        x: win.vertical ? (win.hiddenNow ? parked : start) : win.pad
        y: win.vertical ? win.pad : (win.hiddenNow ? parked : start)
        width: row.width + Theme.dockInnerPad * 2
        height: row.height + Theme.dockInnerPad * 2
        Behavior on x { NumberAnimation { duration: Theme.dur(240); easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: Theme.dur(240); easing.type: Easing.OutCubic } }

        HoverHandler {
            id: bodyHover
            onHoveredChanged: win.hoverChanged(hovered)
        }

        // Subtle multi-layer glass shadow
        Repeater {
            model: [1, 3, 5]
            Rectangle {
                required property int modelData
                x: win.vertical ? 2 - modelData : -modelData
                y: win.vertical ? -modelData : 2 - modelData
                width: body.width + modelData * 2
                height: body.height + modelData * 2
                radius: win.dockConfig.cornerRadius + modelData
                color: Theme.dockShadow
                opacity: win.dockConfig.shadow
            }
        }

        // Neutral translucent glass container with hairline border
        Rectangle {
            anchors.fill: parent
            radius: win.dockConfig.cornerRadius
            color: win.dockConfig.glassColor ? win.dockConfig.glassColor : Pal.Palette.dockGlass
            border.color: win.dockConfig.edgeColor
            border.width: 1
            Behavior on color { ColorAnimation { duration: Theme.dur(180) } }
        }

        // Items laid out along the dock: a row on the bottom or top edge, a column on the sides.
        Grid {
            id: row
            x: Theme.dockInnerPad
            y: Theme.dockInnerPad
            spacing: win.dockConfig.spacing
            flow: win.vertical ? Grid.TopToBottom : Grid.LeftToRight
            // One column on side docks; on the bottom and top edges every item fits in one row.
            columns: win.vertical ? 1 : 1000

            LauncherButton {
                dockState: win.dockState
                iconSize: win.dockConfig.iconSize
                zoom: win.dockConfig.zoom
                side: win.side
            }

            // Separators fill the cell's cross size, so the rule is centred without relying on the row.
            Item {
                visible: win.dockConfig.pinned.length > 0
                width: win.vertical ? win.dockConfig.iconSize + Theme.dockCellPad : 1
                height: win.vertical ? 1 : win.dockConfig.iconSize + 14
                Rectangle {
                    anchors.centerIn: parent
                    width: win.vertical ? win.dockConfig.iconSize * 0.5 : 1
                    height: win.vertical ? 1 : win.dockConfig.iconSize * 0.5
                    color: Pal.Palette.dockRule
                }
            }

            Repeater {
                model: win.dockConfig.pinned
                delegate: DockItem {
                    required property string modelData
                    dockState: win.dockState
                    iconSize: win.dockConfig.iconSize
                    zoom: win.dockConfig.zoom
                    side: win.side
                    entry: win.dockState.entryFor(modelData)
                    label: entry ? entry.name : modelData
                    matchClass: ""
                    visible: entry !== null
                }
            }

            Item {
                visible: win.dockState.running.length > 0
                width: win.vertical ? win.dockConfig.iconSize + Theme.dockCellPad : 1
                height: win.vertical ? 1 : win.dockConfig.iconSize + 14
                Rectangle {
                    anchors.centerIn: parent
                    width: win.vertical ? win.dockConfig.iconSize * 0.5 : 1
                    height: win.vertical ? 1 : win.dockConfig.iconSize * 0.5
                    color: Pal.Palette.dockRule
                }
            }

            Repeater {
                model: win.dockState.running
                delegate: DockItem {
                    required property string modelData
                    dockState: win.dockState
                    iconSize: win.dockConfig.iconSize
                    zoom: win.dockConfig.zoom
                    side: win.side
                    matchClass: modelData
                    entry: win.dockState.entryForClass(modelData)
                    label: entry ? entry.name : modelData
                }
            }
        }
    }
}
