// Dock settings, read from the same files the Python backend already uses:
//   config/config.json       "dock" block: icon_size, auto_hide, margin, and an optional
//                            "monitor" (falls back to the top-level "monitor" key)
//   config/pinned-apps.json  "dock" list of desktop-entry IDs, e.g. "kitty", "com.microsoft.VSCode"
// Both files are watched, so edits apply without restarting the shell.
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    // Quickshell.shellDir is <project>/quickshell; the config lives one level up.
    readonly property string projectDir: {
        const d = String(Quickshell.shellDir).replace(/^file:\/\//, "").replace(/\/+$/, "")
        return d.substring(0, d.lastIndexOf("/"))
    }

    property int iconSize: 48
    property bool autoHide: false
    property int bottomMargin: 10
    property string monitorName: ""
    property var pinned: []

    // Screens the dock should appear on: one named monitor (default), every monitor
    // ("all"), or the first screen when the named one is not connected.
    readonly property var targetScreens: {
        const all = []
        const src = Quickshell.screens
        for (let i = 0; i < src.length; i++) all.push(src[i])
        if (monitorName === "all") return all
        const hit = all.filter(s => s.name === monitorName)
        if (hit.length > 0) return [hit[0]]
        return all.length > 0 ? [all[0]] : []
    }

    function clampInt(v, fallback, lo, hi) {
        if (v === undefined || v === null) return fallback
        const n = Number(v)
        if (!isFinite(n)) return fallback
        return Math.max(lo, Math.min(hi, Math.round(n)))
    }

    function applyConfig(raw) {
        let c = {}
        try { c = JSON.parse(raw) } catch (e) { console.warn("dock: config.json is not valid JSON") }
        const d = c.dock || {}
        root.iconSize = clampInt(d.icon_size, 48, 24, 96)
        root.autoHide = d.auto_hide === true
        root.bottomMargin = clampInt(d.margin, 10, 0, 200)
        root.monitorName = String(d.monitor || c.monitor || "")
    }

    property var pinnedDoc: ({})

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
        path: root.projectDir + "/config/config.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.applyConfig(text())
    }
    FileView {
        id: pinnedFile
        path: root.projectDir + "/config/pinned-apps.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.applyPinned(text())
    }
}
