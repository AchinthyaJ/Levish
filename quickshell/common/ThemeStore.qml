// Levish configuration service — the single source of user preferences.
// Instantiated once in shell.qml and passed down as `themeStore`.
//
// • config/config.json is the only file this service owns. Every key is declared in
//   `schema` with a type, a default and bounds; invalid values fall back to the default.
// • Components bind to the properties below. Nothing else parses config.json.
// • set() / setMany() validate, update the live property (reactive everywhere), then persist.
// • A corrupt config.json is never overwritten silently: it is copied to config.json.bak
//   before the first save, and the shell keeps running on defaults in the meantime.
// • Writes use FileView.atomicWrites, so a crash mid-save cannot leave a half-written file.
import QtQuick
import Quickshell
import Quickshell.Io


Item {
    id: store

    readonly property string projectDir: {
        const d = String(Quickshell.shellDir).replace(/^file:\/\//, "").replace(/\/+$/, "")
        return d.substring(0, d.lastIndexOf("/"))
    }

    // "loading" | "ok" | "missing" | "invalid"  (invalid = unreadable JSON, defaults in use)

    // Derived colors the shell components already consume.
    readonly property color glassColor: Qt.rgba(22 / 255, 38 / 255, 46 / 255, glassOpacity)
    readonly property color glassEdge: "#33ffffff"
    readonly property color dockGlass: Qt.rgba(17 / 255, 19 / 255, 22 / 255, dockOpacity)

    property string status: "loading"
    property string statusDetail: ""
    readonly property string configPath: projectDir + "/config/config.json"

    // ── Live values. Defaults are the Levish Aqua identity. ─────────────────
    property string accentColor: "#c8f7ef"
    property real glassOpacity: 0.85
    property real dockOpacity: 0.76
    property int cornerRadius: 22
    property string fontFamily: "JetBrains Mono"

    property int barHeight: 34
    property string clockFormat: "HH:mm"
    property bool showDate: true
    property bool showSeconds: false
    property bool showGpu: true
    property bool showTemp: true
    property int workspaceFocusedWidth: 40
    property int workspaceHeight: 14
    property int workspaceRadius: 7

    property bool dockEnabled: true
    property int dockIconSize: 48
    property bool dockAutoHide: false
    property int dockMargin: 10
    property string dockMonitor: ""      // "" = first screen, "all" = every screen, or a screen name

    // Wallpaper. Empty path = no wallpaper layer. Empty folder = ~/Pictures/wallpapers.
    property string wallpaperPath: ""
    property string wallpaperFolder: ""

    property string launcherDefaultView: "grid"
    property int launcherColumns: 5

    // ── Schema: every persisted key. `prop` is the live property it drives. ──
    readonly property var schema: ({
        "theme.accent":         { prop: "accentColor",          kind: "color", def: "#c8f7ef" },
        "theme.opacity":        { prop: "glassOpacity",         kind: "real",  def: 0.85, min: 0.3, max: 1.0 },
        "theme.radius":         { prop: "cornerRadius",         kind: "int",   def: 22, min: 4, max: 28 },
        "theme.font_family":    { prop: "fontFamily",           kind: "string",def: "JetBrains Mono", max: 64 },
        "dock.opacity":         { prop: "dockOpacity",          kind: "real",  def: 0.76, min: 0.3, max: 1.0 },

        "bar.height":           { prop: "barHeight",            kind: "int",   def: 34, min: 28, max: 60 },
        "bar.clock_format":     { prop: "clockFormat",          kind: "enum",  def: "HH:mm", choices: ["HH:mm", "hh:mm AP"] },
        "bar.show_date":        { prop: "showDate",             kind: "bool",  def: true },
        "bar.show_seconds":     { prop: "showSeconds",          kind: "bool",  def: false },
        "bar.show_gpu":         { prop: "showGpu",              kind: "bool",  def: true },
        "bar.show_temp":        { prop: "showTemp",             kind: "bool",  def: true },
        "bar.ws_width":         { prop: "workspaceFocusedWidth", kind: "int",  def: 40, min: 20, max: 64 },
        "bar.ws_height":        { prop: "workspaceHeight",      kind: "int",   def: 14, min: 8, max: 24 },
        "bar.ws_radius":        { prop: "workspaceRadius",      kind: "int",   def: 7, min: 3, max: 12 },

        "dock.enabled":         { prop: "dockEnabled",          kind: "bool",  def: true },
        "dock.icon_size":       { prop: "dockIconSize",         kind: "int",   def: 48, min: 24, max: 96 },
        "dock.auto_hide":       { prop: "dockAutoHide",         kind: "bool",  def: false },
        "dock.margin":          { prop: "dockMargin",           kind: "int",   def: 10, min: 0, max: 200 },
        "dock.monitor":         { prop: "dockMonitor",          kind: "string",def: "", max: 64 },

        "launcher.default_view":{ prop: "launcherDefaultView",  kind: "enum",  def: "grid", choices: ["grid", "list"] },
        "launcher.columns":     { prop: "launcherColumns",      kind: "int",   def: 5, min: 3, max: 8 },
        "wallpaper.path":       { prop: "wallpaperPath",        kind: "string",def: "", max: 4096 },
        "wallpaper.folder":     { prop: "wallpaperFolder",      kind: "string",def: "", max: 4096 }
    })

    // Keys the settings app may reset, in display order.
    readonly property var schemaPaths: Object.keys(schema)

    // Keeps the whole document, so keys this service does not own (shortcuts, metrics_interval…)
    // survive every save untouched.
    property var doc: ({})

    // ── Validation ──────────────────────────────────────────────────────────
    function coerce(entry, value) {
        if (value === undefined || value === null) return undefined
        switch (entry.kind) {
        case "color": {
            const s = String(value).trim().toLowerCase()
            return /^#[0-9a-f]{6}$/.test(s) ? s : undefined
        }
        case "real": {
            const n = Number(value)
            if (typeof value === "boolean" || !isFinite(n)) return undefined
            return Math.max(entry.min, Math.min(entry.max, n))
        }
        case "int": {
            const n = Number(value)
            if (typeof value === "boolean" || !isFinite(n)) return undefined
            return Math.max(entry.min, Math.min(entry.max, Math.round(n)))
        }
        case "bool":
            return typeof value === "boolean" ? value : undefined
        case "enum":
            return entry.choices.indexOf(value) >= 0 ? value : undefined
        case "string":
            return typeof value === "string" && value.length <= entry.max ? value : undefined
        }
        return undefined
    }

    function _split(path) {
        const i = path.indexOf(".")
        return i < 0 ? ["", path] : [path.substring(0, i), path.substring(i + 1)]
    }

    function _rawFor(d, path) {
        const parts = _split(path)
        if (parts[0] === "") return d[parts[1]]
        return d[parts[0]] ? d[parts[0]][parts[1]] : undefined
    }

    // Reads the live value for a schema path.
    function valueOf(path) {
        const e = schema[path]
        return e ? store[e.prop] : undefined
    }

    // ── Loading ─────────────────────────────────────────────────────────────
    function _load(raw) {
        let parsed = null
        try {
            parsed = JSON.parse(raw)
            if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) throw new Error("root is not an object")
        } catch (e) {
            console.warn("ThemeStore: config.json is unreadable, using defaults: " + e)
            store.doc = ({})
            store._backedUp = false
            _applyDefaults()
            store.status = "invalid"
            store.statusDetail = "config.json could not be parsed; defaults are in use."
            return
        }
        store.doc = parsed
        let bad = []
        for (const path of schemaPaths) {
            const e = schema[path]
            const v = coerce(e, _rawFor(parsed, path))
            if (v === undefined) {
                if (_rawFor(parsed, path) !== undefined) bad.push(path)
                store[e.prop] = e.def
            } else {
                store[e.prop] = v
            }
        }
        // Legacy top-level "monitor" (used by older configs) feeds the dock when dock.monitor is empty.
        if (store.dockMonitor === "" && typeof parsed.monitor === "string") store.dockMonitor = parsed.monitor
        store.status = "ok"
        store.statusDetail = bad.length ? (bad.length + " invalid value(s) reset to defaults: " + bad.join(", ")) : ""
    }

    function _applyDefaults() {
        for (const path of schemaPaths) store[schema[path].prop] = schema[path].def
    }

    FileView {
        id: configFile
        path: store.configPath
        watchChanges: true
        atomicWrites: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: store._load(text())
        onLoadFailed: (err) => {
            // FileNotFound means a fresh install: defaults, and the file is created on first save.
            if (err === FileViewError.FileNotFound) {
                store.doc = ({})
                store._applyDefaults()
                store.status = "missing"
                store.statusDetail = "config.json does not exist yet; defaults are in use."
            } else {
                store.status = "invalid"
                store.statusDetail = "config.json could not be read."
            }
        }
    }

    // Preserves a corrupt file once, before the first write replaces it.
    FileView {
        id: backupFile
        path: store.configPath + ".bak"
        atomicWrites: true
        printErrors: false
    }
    property bool _backedUp: false

    // ── Writing ─────────────────────────────────────────────────────────────
    // Applies [[path, value], …] in one go and persists once. Returns the list of rejected paths.
    function setMany(pairs) {
        const rejected = []
        // Never write before the file has loaded: that would replace the user's document with a partial one.
        if (store.status === "loading") return pairs.map(p => p[0])
        const next = JSON.parse(JSON.stringify(store.doc))
        let changed = false
        for (const [path, value] of pairs) {
            const e = schema[path]
            const v = e ? coerce(e, value) : undefined
            if (v === undefined) { rejected.push(path); continue }
            const parts = _split(path)
            if (parts[0] === "") {
                next[parts[1]] = v
            } else {
                if (typeof next[parts[0]] !== "object" || next[parts[0]] === null) next[parts[0]] = {}
                next[parts[0]][parts[1]] = v
            }
            store[e.prop] = v
            changed = true
        }
        if (changed) _persist(next)
        return rejected
    }

    function set(path, value) {
        return setMany([[path, value]]).length === 0
    }

    // Resets the given paths (default: every schema key) to their defaults.
    function resetPaths(paths) {
        const list = paths && paths.length ? paths : schemaPaths
        return setMany(list.map(p => [p, schema[p].def]))
    }

    function _persist(next) {
        if (status === "invalid" && !_backedUp) {
            // Keep the user's broken file recoverable before we replace it.
            _backedUp = true
            backupFile.setText(configFile.text())
        }
        store.doc = next
        configFile.setText(JSON.stringify(next, null, 2) + "\n")
        if (status !== "ok") { status = "ok"; statusDetail = "" }
    }

    // ── Presets for the accent swatches (kept deliberately small) ────────────
    readonly property var accentSwatches: [
        { name: "Aqua",     hex: "#c8f7ef" },
        { name: "Turquoise", hex: "#2dd4bf" },
        { name: "Cyan",     hex: "#38bdf8" },
        { name: "Blue",     hex: "#60a5fa" },
        { name: "Purple",   hex: "#a78bfa" },
        { name: "Green",    hex: "#34d399" },
        { name: "Orange",   hex: "#fb923c" },
        { name: "Red",      hex: "#f87171" }
    ]
}
