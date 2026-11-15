// Clipboard history for text. Event-driven: `wl-paste --watch` runs a helper each time the Wayland
// clipboard changes, so nothing polls.
//
// Privacy:
// • Off by default (Settings → Clipboard). While off, nothing is watched or recorded.
// • History is kept in memory only. It is never written to disk and is cleared when the shell restarts.
// • Only text is recorded, and copies longer than 20 000 characters are skipped.
//
// Encoding: the helper turns newlines into the ASCII record separator (0x1E) so each copy is a single
// stdout line. The decoder turns them back into newlines, so multi-line text copies back intact.
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: svc
    required property var themeStore

    readonly property int maxChars: 20000
    // [{ text, pinned, time }], newest first. Pinned entries are kept when the history is trimmed.
    property var entries: []
    // "off" | "watching" | "unavailable"
    property string status: "off"

    function _trim(list) {
        const max = svc.themeStore.clipboardMax
        let unpinned = 0
        const out = []
        for (const e of list) {
            if (e.pinned) { out.push(e); continue }
            if (unpinned < max) { out.push(e); unpinned++ }
        }
        return out
    }

    function _add(text) {
        if (text.trim() === "" || text.length > svc.maxChars) return
        const existing = svc.entries.find(e => e.text === text)
        const entry = { text: text, pinned: existing ? existing.pinned : false, time: Qt.formatTime(new Date(), "HH:mm:ss") }
        // A copy that is already in the history moves to the top rather than being added twice.
        svc.entries = _trim([entry].concat(svc.entries.filter(e => e.text !== text)))
    }

    function _indexOf(text) {
        for (let i = 0; i < svc.entries.length; i++) if (svc.entries[i].text === text) return i
        return -1
    }

    function togglePin(text) {
        const i = _indexOf(text)
        if (i < 0) return
        const list = svc.entries.slice()
        list[i] = Object.assign({}, list[i], { pinned: !list[i].pinned })
        svc.entries = list
    }

    function remove(text) { svc.entries = svc.entries.filter(e => e.text !== text) }
    function clearUnpinned() { svc.entries = svc.entries.filter(e => e.pinned) }
    function clearAll() { svc.entries = [] }

    // Puts a history entry back on the clipboard. The text is passed as an argument, never spliced into
    // the shell command, so quotes and $(...) in a copied string are just text.
    function copyBack(text) {
        restoreProc.running = false
        restoreProc.command = ["sh", "-c", 'printf %s "$1" | wl-copy', "sh", text]
        restoreProc.running = true
    }

    onStatusChanged: console.log("clipboard: " + status)

    // Watcher. Starts and stops with the Settings toggle.
    Process {
        id: watcher
        running: svc.themeStore.clipboardEnabled
        command: ["wl-paste", "--type", "text", "--watch", "sh", "-c", "cat | tr '\\n' '\\036'; printf '\\n'"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (data) => {
                const text = data.split("\x1e").join("\n").replace(/\n$/, "")
                svc._add(text)
            }
        }
        onRunningChanged: {
            if (running) svc.status = "watching"
            else if (svc.themeStore.clipboardEnabled) svc.status = "unavailable"
            else { svc.status = "off" }
        }
        onExited: (code) => { if (code !== 0) svc.status = "unavailable" }
    }

    Process { id: restoreProc }
}
