// Dock wiring. Dock preferences come from the shared ThemeStore instance (common/ThemeStore.qml),
// so the settings app and the dock always agree. This file adds only what ThemeStore does not own:
//   config/pinned-apps.json  "dock" list of desktop-entry IDs, e.g. "kitty", "com.microsoft.VSCode"
// The pinned file is watched, so edits apply without restarting the shell.
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    // Passed in from shell.qml.
    required property var themeStore

    // Quickshell.shellDir is <project>/quickshell; the config lives one level up.
    readonly property string projectDir: {
        const d = String(Quickshell.shellDir).replace(/^file:\/\//, "").replace(/\/+$/, "")
        return d.substring(0, d.lastIndexOf("/"))
    }

    readonly property int iconSize: themeStore.dockIconSize
    readonly property int cornerRadius: themeStore.cornerRadius
    readonly property int spacing: themeStore.dockSpacing
    readonly property real zoom: themeStore.dockZoom
    readonly property real shadow: themeStore.dockShadow
    readonly property color edgeColor: Qt.rgba(1, 1, 1, themeStore.borderStrength)
    readonly property bool autoHide: themeStore.dockAutoHide
    readonly property bool enabled: themeStore.dockEnabled
    readonly property int bottomMargin: themeStore.dockMargin
    // Screen edge the dock sits on: bottom, top, left or right.
    readonly property string position: themeStore.dockPosition
    readonly property string monitorName: themeStore.dockMonitor
    readonly property color glassColor: themeStore.dockGlass

    property var pinned: []
    property var pinnedDoc: ({})

    // Screens the dock should appear on: every screen ("all"), the named one,
    // or the first screen when the named one is not connected or no name is set.
    readonly property var targetScreens: {
        const all = []
        const src = Quickshell.screens
        for (let i = 0; i < src.length; i++) all.push(src[i])
        if (monitorName === "all") return all
        const hit = all.filter(s => s.name === monitorName)
        if (hit.length > 0) return [hit[0]]
        return all.length > 0 ? [all[0]] : []
    }

    function applyPinned(raw) {
        try {
            const p = JSON.parse(raw)
            root.pinnedDoc = p
            root.pinned = Array.isArray(p.dock) ? p.dock.filter(s => typeof s === "string" && s.length > 0) : []
        } catch (e) {
            console.warn("dock: pinned-apps.json is not valid JSON")
            root.pinned = []
        }
    }

    // Writes the new dock list. The FileView watch reloads it, so every view updates.
    function savePinned(list) {
        const doc = Object.assign({}, root.pinnedDoc, { dock: list })
        pinnedFile.setText(JSON.stringify(doc, null, 2) + "\n")
        root.pinnedDoc = doc
        root.pinned = list
    }

    FileView {
        id: pinnedFile
        path: root.projectDir + "/config/pinned-apps.json"
        watchChanges: true
        atomicWrites: true
        onFileChanged: reload()
        onLoaded: root.applyPinned(text())
    }
}
