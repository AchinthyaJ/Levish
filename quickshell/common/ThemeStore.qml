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

    // Wallpaper. Empty path = fallback to /usr/share/hypr/wall0.png.
    property string wallpaperPath: "/usr/share/hypr/wall0.png"
    property string wallpaperFolder: ""
    property string wallpaperFit: "cover"
    property bool wallpaperAutoRotate: false
    property int wallpaperInterval: 1800
    property var wallpaperList: []

    // Notifications. Do-not-disturb is runtime state and lives in the notification service, not here.
    property bool notificationsEnabled: true
    property int notificationTimeout: 5000
    property string notificationPosition: "top-right"
    property int notificationMaxVisible: 3

    // On-screen display: which events show it, and for how long.
    property bool osdVolume: true
    property bool osdBrightness: true
    property bool osdKeyboard: true
    property int osdTimeout: 2000

    // Clipboard history. Off by default: it records what you copy, so it is opt-in. History is kept
    // in memory only and is never written to disk.
    property bool clipboardEnabled: false
    property int clipboardMax: 50

    // Night light (hyprsunset). Off by default. Caffeine is runtime state and is not stored here.
    property bool nightlightEnabled: false
    property int nightlightTemp: 4000

    // Lock screen: auto-lock after N minutes idle (0 = never), and lock before sleep.
    property int lockTimeoutMin: 0
    property bool lockBeforeSleep: false
    property string lockLayout: "cinematic"
    property string lockClockFormat: "HH:mm"
    property bool lockShowSeconds: false
    property real lockClockScale: 1.0
    property bool lockUseDesktopWallpaper: true
    property string lockCustomWallpaperPath: ""
    property int lockBlur: 32
    property real lockDimming: 0.45
    property real lockVignette: 0.5
    property bool lockAmbientEffects: true
    property bool lockReducedMotion: false
    property bool lockShowGreeting: true
    property string lockCustomGreeting: ""
    property bool lockShowDisplayName: true
    property bool lockShowUsername: true
    property bool lockShowHostname: false
    property string lockCustomAvatar: ""
    property bool lockShowWeather: true
    property string lockWeatherLocation: ""
    property string lockWeatherUnits: "C"
    property bool lockShowBattery: true
    property bool lockShowNetwork: true
    property bool lockShowMedia: true
    property bool lockShowUptime: false
    property bool lockHideSensitiveMedia: false
    property bool lockHideUserDetails: false
    property bool lockDisableWidgets: false

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
        "wallpaper.path":       { prop: "wallpaperPath",        kind: "string",def: "/usr/share/hypr/wall0.png", max: 4096 },
        "wallpaper.folder":     { prop: "wallpaperFolder",      kind: "string",def: "", max: 4096 },
        "wallpaper.fit":        { prop: "wallpaperFit",         kind: "enum",  def: "cover", choices: ["cover", "contain", "stretch", "tile"] },
        "wallpaper.auto_rotate":{ prop: "wallpaperAutoRotate",  kind: "bool",  def: false },
        "wallpaper.interval":   { prop: "wallpaperInterval",    kind: "int",   def: 1800, min: 30, max: 86400 },

        "notifications.enabled":      { prop: "notificationsEnabled",  kind: "bool",  def: true },
        "notifications.timeout_ms":   { prop: "notificationTimeout",   kind: "int",   def: 5000, min: 1000, max: 60000 },
        "notifications.position":     { prop: "notificationPosition",  kind: "enum",  def: "top-right", choices: ["top-right", "top-left", "bottom-right", "bottom-left"] },
        "notifications.max_visible":  { prop: "notificationMaxVisible", kind: "int",   def: 3, min: 1, max: 6 },

        "osd.volume":           { prop: "osdVolume",            kind: "bool",  def: true },
        "osd.brightness":       { prop: "osdBrightness",        kind: "bool",  def: true },
        "osd.keyboard":         { prop: "osdKeyboard",          kind: "bool",  def: true },
        "osd.timeout_ms":       { prop: "osdTimeout",           kind: "int",   def: 2000, min: 800, max: 6000 },

        "clipboard.enabled":    { prop: "clipboardEnabled",     kind: "bool",  def: false },
        "clipboard.max_items":  { prop: "clipboardMax",         kind: "int",   def: 50, min: 5, max: 200 },

        "nightlight.enabled":   { prop: "nightlightEnabled",    kind: "bool",  def: false },
        "nightlight.temperature": { prop: "nightlightTemp",     kind: "int",   def: 4000, min: 2500, max: 6500 },

        "lock.timeout_min":     { prop: "lockTimeoutMin",       kind: "int",   def: 0, min: 0, max: 120 },
        "lock.before_sleep":    { prop: "lockBeforeSleep",      kind: "bool",  def: false },
        "lock.layout":          { prop: "lockLayout",           kind: "enum",  def: "cinematic", choices: ["cinematic", "editorial", "minimal", "split"] },
        "lock.clock_format":    { prop: "lockClockFormat",      kind: "enum",  def: "HH:mm", choices: ["HH:mm", "hh:mm AP"] },
        "lock.show_seconds":    { prop: "lockShowSeconds",      kind: "bool",  def: false },
        "lock.clock_scale":     { prop: "lockClockScale",       kind: "real",  def: 1.0, min: 0.7, max: 1.6 },
        "lock.use_desktop_wallpaper": { prop: "lockUseDesktopWallpaper", kind: "bool", def: true },
        "lock.custom_wallpaper_path": { prop: "lockCustomWallpaperPath", kind: "string", def: "", max: 4096 },
        "lock.blur":            { prop: "lockBlur",             kind: "int",   def: 32, min: 0, max: 64 },
        "lock.dimming":         { prop: "lockDimming",          kind: "real",  def: 0.45, min: 0.0, max: 0.95 },
        "lock.vignette":        { prop: "lockVignette",         kind: "real",  def: 0.5, min: 0.0, max: 1.0 },
        "lock.ambient_effects": { prop: "lockAmbientEffects",   kind: "bool",  def: true },
        "lock.reduced_motion":  { prop: "lockReducedMotion",    kind: "bool",  def: false },
        "lock.show_greeting":   { prop: "lockShowGreeting",     kind: "bool",  def: true },
        "lock.custom_greeting": { prop: "lockCustomGreeting",   kind: "string",def: "", max: 128 },
        "lock.show_display_name": { prop: "lockShowDisplayName",kind: "bool",  def: true },
        "lock.show_username":   { prop: "lockShowUsername",     kind: "bool",  def: true },
        "lock.show_hostname":   { prop: "lockShowHostname",     kind: "bool",  def: false },
        "lock.custom_avatar":   { prop: "lockCustomAvatar",     kind: "string",def: "", max: 4096 },
        "lock.show_weather":    { prop: "lockShowWeather",      kind: "bool",  def: false },
        "lock.weather_location":{ prop: "lockWeatherLocation",  kind: "string",def: "", max: 128 },
        "lock.weather_units":   { prop: "lockWeatherUnits",     kind: "enum",  def: "C", choices: ["C", "F"] },
        "lock.show_battery":    { prop: "lockShowBattery",      kind: "bool",  def: true },
        "lock.show_network":    { prop: "lockShowNetwork",      kind: "bool",  def: true },
        "lock.show_media":      { prop: "lockShowMedia",        kind: "bool",  def: true },
        "lock.show_uptime":     { prop: "lockShowUptime",       kind: "bool",  def: false },
        "lock.hide_sensitive_media": { prop: "lockHideSensitiveMedia", kind: "bool", def: false },
        "lock.hide_user_details": { prop: "lockHideUserDetails", kind: "bool", def: false },
        "lock.disable_widgets": { prop: "lockDisableWidgets",   kind: "bool",  def: false }
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
        const applied = []
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
            applied.push({ path: path, value: String(v), time: Qt.formatTime(new Date(), "HH:mm:ss") })
            changed = true
        }
        if (changed) {
            _persist(next)
            // Session-only history for the Settings overview. It is never written to config.json.
            store.recentChanges = applied.concat(store.recentChanges).slice(0, 8)
        }
        return rejected
    }

    // Last changes made in this session, newest first. Not persisted.
    property var recentChanges: []

    function set(path, value) {
        return setMany([[path, value]]).length === 0
    }

    // Convenience function for setting wallpaper list
    function setWallpaperList(list) {
        if (Array.isArray(list)) store.wallpaperList = list
    }

    // Compatibility alias: saveSetting("wallpaper", "path", val) -> set("wallpaper.path", val)
    function saveSetting(category, key, value) {
        return set(category + "." + key, value)
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
