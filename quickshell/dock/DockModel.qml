// Decides which applications the dock shows and which Hyprland windows belong to each.
// Event-driven: it updates on Hyprland IPC events and when the desktop-entry database
// changes. There are no timers and no polling.
import QtQuick
import Quickshell
import Quickshell.Hyprland

Scope {
    id: root
    required property var dockConfig

    property int appsRevision: 0      // bumped when the installed-app database changes
    property var running: []          // window classes of open apps that are not pinned
    property string runningKey: ""    // change detector, so the list is only replaced on change

    function listOf(m) { return m && m.values !== undefined ? m.values : (m || []) }

    // ── Window helpers (Hyprland IPC data lives on lastIpcObject) ─────────
    function classOf(t) {
        const ipc = t.lastIpcObject
        return ipc && ipc.class ? String(ipc.class) : ""
    }
    function addressOf(t) {
        const ipc = t.lastIpcObject
        let a = (ipc && ipc.address) ? String(ipc.address) : String(t.address || "")
        if (a && a.indexOf("0x") !== 0) a = "0x" + a
        return a
    }
    // focusHistoryID 0 is the window that currently has focus.
    function isFocused(t) {
        const ipc = t.lastIpcObject
        return !!ipc && ipc.focusHistoryID === 0
    }
    function focusRank(t) {
        const ipc = t.lastIpcObject
        return ipc && typeof ipc.focusHistoryID === "number" ? ipc.focusHistoryID : 1e9
    }

    // ── Desktop-entry matching ────────────────────────────────────────────
    // A window belongs to an entry when its class equals the entry's StartupWMClass, the
    // entry ID, or the last dotted part of the ID (org.gnome.Nautilus -> nautilus).
    function classMatches(cls, entry) {
        if (!entry || !cls) return false
        const c = cls.toLowerCase()
        if (entry.startupClass && entry.startupClass.toLowerCase() === c) return true
        const id = entry.id.toLowerCase()
        return id === c || id.split(".").pop() === c
    }
    function execBinary(entry) {
        const first = (entry.execString || "").trim().split(/\s+/)[0] || ""
        return first.split("/").pop().toLowerCase()
    }

    // Resolves a pinned token: exact desktop ID, then case-insensitive ID or name, then
    // the executable name, so "code" finds com.microsoft.VSCode. Null when not installed.
    function entryFor(token) {
        void root.appsRevision
        if (!token) return null
        const key = String(token).replace(/\.desktop$/i, "")
        const direct = DesktopEntries.byId(key)
        if (direct) return direct
        const lower = key.toLowerCase()
        const apps = listOf(DesktopEntries.applications)
        for (const a of apps) {
            if (a.id.toLowerCase() === lower || a.name.toLowerCase() === lower) return a
        }
        for (const a of apps) {
            if (execBinary(a) === lower) return a
        }
        return null
    }

    // Entry for an unpinned running window class (icon and name only; may be null).
    function entryForClass(cls) {
        void root.appsRevision
        const direct = DesktopEntries.byId(cls)
        if (direct) return direct
        for (const a of listOf(DesktopEntries.applications)) {
            if (classMatches(cls, a)) return a
        }
        return null
    }

    // Every open window for an app, most recently focused first.
    function windowsFor(entry, cls) {
        const want = cls ? cls.toLowerCase() : ""
        const out = []
        for (const t of listOf(Hyprland.toplevels)) {
            const c = classOf(t)
            if (!c) continue
            if ((want && c.toLowerCase() === want) || classMatches(c, entry)) out.push(t)
        }
        out.sort((a, b) => focusRank(a) - focusRank(b))
        return out
    }

    function focusWindow(t) {
        const addr = addressOf(t)
        if (addr) Hyprland.dispatch('hl.dsp.focus({ window = "address:' + addr + '" })')
    }

    // ── Pinning: writes config/pinned-apps.json (same file the Python backend uses) ──
    function isPinned(entry) {
        if (!entry) return false
        for (const t of dockConfig.pinned) if (entryFor(t) === entry) return true
        return false
    }
    function togglePin(entry) {
        if (!entry) return
        let list
        if (isPinned(entry)) {
            list = dockConfig.pinned.filter(t => entryFor(t) !== entry)
        } else {
            list = dockConfig.pinned.concat([entry.id])
        }
        dockConfig.savePinned(list)
    }

    // The dock's launcher button asks the shell to toggle the Quickshell launcher.
    signal launcherRequested()
    function openLauncher() { launcherRequested() }

    // Rebuilds the list of running apps that are not pinned. It is only reassigned when the
    // set of classes changes, so the Repeater does not recreate delegates needlessly.
    function refreshRunning() {
        const pinnedEntries = dockConfig.pinned.map(id => entryFor(id))
        const seen = {}
        const list = []
        for (const t of listOf(Hyprland.toplevels)) {
            const c = classOf(t)
            if (!c) continue
            const lc = c.toLowerCase()
            if (seen[lc]) continue
            seen[lc] = true
            if (pinnedEntries.some(e => classMatches(c, e))) continue
            list.push(c)
        }
        const key = list.join("\n")
        if (key !== runningKey) {
            runningKey = key
            running = list
        }
    }

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            root.appsRevision++
            root.refreshRunning()
        }
    }
    Connections {
        target: Hyprland
        function onRawEvent(event) { root.refreshRunning() }
    }
    Connections {
        target: root.dockConfig
        function onPinnedChanged() { root.refreshRunning() }
    }

    Component.onCompleted: {
        Hyprland.refreshToplevels()
        refreshRunning()
    }
}
