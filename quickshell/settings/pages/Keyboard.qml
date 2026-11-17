import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../components"
import "../../common/Theme.js" as Theme
import "../../common" as Pal

// Keyboard & shortcuts: the keybinds Hyprland has loaded, read-only, with conflict detection.
// Editing binds is not offered yet: changes would need writing Hyprland config and a reload.
Flickable {
    id: page
    property var themeStore
    property var hypr                  // HyprQuery
    property string pageId: ""
    ScrollBar.vertical: PageScrollBar { accent: page.themeStore.accentColor }
    property string keywords: "keyboard keybind keybinding shortcut shortcuts key binding conflict super mod hyprland layout"
    readonly property var resetPaths: []
    readonly property color accent: themeStore.accentColor

    // Hyprland modifier bits (hyprctl modmask).
    function modsText(m) {
        const parts = []
        if (m & 64) parts.push("Super")
        if (m & 4) parts.push("Ctrl")
        if (m & 8) parts.push("Alt")
        if (m & 1) parts.push("Shift")
        return parts.join(" + ")
    }
    function comboText(b) {
        const mods = modsText(b.modmask)
        return (mods !== "" ? mods + " + " : "") + b.key
    }
    // Same key combination in the same submap = a conflict; the later one never fires.
    function conflictKey(b) { return b.modmask + "|" + String(b.key).toLowerCase() + "|" + (b.submap || "") }
    function conflictCount(list) {
        const counts = {}
        for (const b of list) counts[conflictKey(b)] = (counts[conflictKey(b)] || 0) + 1
        return counts
    }
    readonly property var counts: hypr ? conflictCount(hypr.binds) : ({})
    readonly property int conflictTotal: {
        let n = 0
        for (const k in counts) if (counts[k] > 1) n += counts[k]
        return n
    }

    contentHeight: col.implicitHeight + 40
    clip: true

    ColumnLayout {
        id: col
        x: Theme.space5; y: Theme.space4
        width: page.width - Theme.space5 * 2
        spacing: Theme.space3

        SettingsCard {
            title: "Hyprland keybinds"
            SettingsRow {
                label: !page.hypr ? "Hyprland not connected"
                     : page.hypr.status === "loading" ? "Reading keybinds…"
                     : page.hypr.status === "error" ? "Could not read keybinds"
                     : (page.hypr.binds.length + " binds loaded")
                hint: !page.hypr ? "" : (page.hypr.status === "error" ? page.hypr.error
                     : (page.conflictTotal > 0 ? page.conflictTotal + " entries share a key combination. Only one of each set can fire."
                                               : "No conflicting key combinations."))
                SettingsButton { text: "Refresh"; onClicked: page.hypr.refresh() }
            }
            SettingsRow {
                label: "Editing shortcuts"
                hint: "Shortcuts are shown here as Hyprland has them loaded. Editing them is not available yet."
                Text { text: "Read-only"; color: Pal.Palette.muted; font.pixelSize: Theme.fontSmall }
            }
        }

        SettingsCard {
            title: "Shortcuts"
            Repeater {
                model: page.hypr ? page.hypr.binds : []
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool conflict: (page.counts[page.conflictKey(modelData)] || 0) > 1
                    width: parent ? parent.width : 300
                    implicitHeight: rowL.implicitHeight + 14
                    radius: Theme.radiusRow
                    color: Pal.Palette.controlFill
                    border.color: conflict ? Pal.Palette.warning : Pal.Palette.surfaceEdge

                    RowLayout {
                        id: rowL
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 10 }
                        spacing: 10
                        Text {
                            Layout.preferredWidth: 220
                            text: page.comboText(modelData)
                            color: Pal.Palette.textPrimary
                            font.pixelSize: Theme.fontSmall
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modelData.dispatcher + (modelData.arg !== "" ? "  " + modelData.arg : "")
                                  + (modelData.submap ? "   [" + modelData.submap + "]" : "")
                            color: Pal.Palette.textSecondary
                            font.pixelSize: Theme.fontCaption
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                        }
                        Text {
                            visible: conflict
                            text: "CONFLICT"
                            color: Pal.Palette.warning
                            font.pixelSize: Theme.fontCaption
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }
            Text {
                visible: page.hypr && page.hypr.binds.length === 0 && page.hypr.status === "ok"
                Layout.fillWidth: true
                text: "Hyprland reports no keybinds."
                color: Pal.Palette.muted
                font.pixelSize: Theme.fontSmall
            }
        }
    }
}
