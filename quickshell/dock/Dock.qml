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
    // While auto-hidden the surface itself shrinks to the 16 px reveal strip. Resizing the layer
    // surface makes the compositor redraw it, so the dock cannot linger as stale pixels, and no
    // empty transparent area is left reserved above the screen edge.
    readonly property bool hiddenNow: autoHide && !shown
    readonly property real fullHeight: tipRoom + body.height + bottomGap
    implicitHeight: hiddenNow ? 16 : fullHeight
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
        x: win.pad
        // Parked below the full height (outside the 16 px hidden surface) while auto-hidden.
        y: win.hiddenNow ? win.fullHeight : win.tipRoom
        width: row.width + Theme.dockInnerPad * 2
        height: row.height + Theme.dockInnerPad * 2
        Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        HoverHandler {
            id: bodyHover
            onHoveredChanged: win.hoverChanged(hovered)
        }

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
