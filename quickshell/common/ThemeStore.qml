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
import "ConfigSchema.js" as Schema
import "Theme.js" as Theme


Item {
    id: store

    readonly property string projectDir: {
        const d = String(Quickshell.shellDir).replace(/^file:\/\//, "").replace(/\/+$/, "")
        return d.substring(0, d.lastIndexOf("/"))
    }

    // "loading" | "ok" | "missing" | "invalid"  (invalid = unreadable JSON, defaults in use)

    // Derived colors the shell components already consume.
    readonly property color glassColor: Qt.rgba(barBase.r, barBase.g, barBase.b, glassOpacity)
    readonly property color dockGlass: Qt.rgba(dockBase.r, dockBase.g, dockBase.b, dockOpacity)

    // Palette: opaque base colours. Opacity is applied separately (theme.opacity, dock.opacity).
    readonly property color barBase: paletteBar
    readonly property color dockBase: paletteDock
    property string paletteWindow: "#14161c"
    property string paletteSidebar: "#0f1116"
    property string paletteBar: "#16262e"
    property string paletteDock: "#111316"
    property string paletteText: "#f5f9fd"
    property string paletteTextSecondary: "#c9d6e8"
    property string paletteMuted: "#9fb0c6"
    property string paletteInk: "#ffffff"
    property string paletteIconTile: "#1f2a33"
    property string paletteOk: "#34d399"
    property string paletteWarning: "#fb923c"
    property string paletteDanger: "#f0708a"
    property string paletteCard: "#213842"
    property string paletteCardEdge: "#2a4452"

    property string status: "loading"
    property string statusDetail: ""
    readonly property string configPath: projectDir + "/config/config.json"

    // ── Live values. Defaults are the Levish Aqua identity. ─────────────────
    // Plain default: Palette reads this value, so it must not read the palette back.
    property string accentColor: Theme.accent
    property real glassOpacity: 0.85
    property real dockOpacity: 0.76
    property int cornerRadius: 22
    property string fontFamily: "JetBrains Mono"

    property int barHeight: 34
    property string clockFormat: "HH:mm"
    property bool showDate: true
    property bool showSeconds: false
    property bool showGpu: true
    // Top bar zones. Each can be hidden; the bar keeps working without it.
    property bool showPerf: true
    property bool showWorkspaces: true
    property bool showWindowTitle: true
    property bool showClock: true
    property bool showStatus: true
    property bool showTray: true
    property bool showTemp: true
    property int workspaceFocusedWidth: 40
    property int workspaceHeight: 14
    property int workspaceRadius: 7

    property bool dockEnabled: true
    property int dockIconSize: 48
    property bool dockAutoHide: false
    property int dockSpacing: 4
    property real dockShadow: 1.0
    property string dockPosition: "bottom"
    // Border strength for the dock (theme.border) and an optional outline on the bar (bar.border).
    property real borderStrength: 0.2
    property real barBorder: 0.0
    // Top bar placement: which edge, distance from that edge, distance from the sides, corner radius.
    property string barPosition: "top"
    property int barGap: 0
    property int barSideMargin: 0
    property int barRadius: 0
    property real dockZoom: 1.12
    property int dockMargin: 10
    property string dockMonitor: ""      // "" = first screen, "all" = every screen, or a screen name

    // Wallpaper. Empty path = fallback to /usr/share/hypr/wall0.png.
    property string wallpaperPath: "/usr/share/hypr/wall0.png"
    property string wallpaperFolder: ""
    // Per-monitor overrides, "DP-1=/path/a.png;HDMI-A-1=/path/b.png". Monitors not listed use wallpaper.path.
    property string wallpaperMonitors: ""
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

    // Shell-wide reduced motion, and the Settings page to open on start.
    property bool reducedMotion: false
    // Text scale. Read when text is created, so a change is complete after a shell restart.
    property real fontScale: 1.0
    onFontScaleChanged: Theme.fontScale = fontScale
    onReducedMotionChanged: Theme.motionScale = reducedMotion ? 0 : 1
    property string settingsLastPage: "overview"

    property string launcherDefaultView: "grid"
    property int launcherIconSize: 42
    property string launcherSort: "name"
    // Desktop IDs hidden from the launcher, comma separated (for example "htop,avahi-discover").
    property string launcherHidden: ""
    property int launcherColumns: 5

    // ── Schema: every persisted key, defined in common/ConfigSchema.js ────────
    readonly property var schema: Schema.schema

    // Keys the settings app may reset, in display order.
    readonly property var schemaPaths: Schema.schemaPaths()

    // Keeps the whole document, so keys this service does not own (shortcuts, metrics_interval…)
    // survive every save untouched.
    property var doc: ({})

    // ── Validation ──────────────────────────────────────────────────────────
    function coerce(entry, value) { return Schema.coerce(entry, value) }

    // Reads the live value for a schema path.
    function valueOf(path) {
        const e = schema[path]
        return e ? store[e.prop] : undefined
    }

    // ── Loading ─────────────────────────────────────────────────────────────
    function _load(raw) {
        let result = null
        try {
            result = Schema.load(raw)
        } catch (e) {
            console.warn("ThemeStore: config.json is unreadable, using defaults: " + e)
            store.doc = ({})
            store._backedUp = false
            _applyDefaults()
            store.status = "invalid"
            store.statusDetail = "config.json could not be parsed; defaults are in use."
            return
        }
        store.doc = result.doc
        store._newer = result.newer
        for (const path of schemaPaths) store[schema[path].prop] = result.values[path]
        store.status = "ok"
        const notes = []
        if (result.newer) notes.push("written by a newer Levish; unknown settings are kept as they are")
        if (result.rejected.length) notes.push(result.rejected.length + " invalid value(s) reset to defaults: " + result.rejected.join(", "))
        store.statusDetail = notes.join(". ")
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
    property bool _newer: false

    // ── Writing ─────────────────────────────────────────────────────────────
    // Applies [[path, value], …] in one go and persists once. Returns the list of rejected paths.
    function setMany(pairs) {
        const rejected = []
        // Never write before the file has loaded: that would replace the user's document with a partial one.
        if (store.status === "loading") return pairs.map(p => p[0])
        // A file written by a newer Levish would be downgraded on save. Leave it alone instead.
        if (store._newer) return pairs.map(p => p[0])
        const next = JSON.parse(JSON.stringify(store.doc))
        let changed = false
        const applied = []
        for (const [path, value] of pairs) {
            const e = schema[path]
            const v = e ? coerce(e, value) : undefined
            if (v === undefined) { rejected.push(path); continue }
            Schema.writeFor(next, path, v)
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

    // ── Import and export (text, so it works without a file dialog) ─────────
    // The settings document as text, ready to copy or save.
    function exportText() { return Schema.serialize(store.doc) }

    // Applies a settings document. Only keys present in it change; everything else is kept.
    // Returns { ok, applied, rejected, error }. Nothing is written when the text is not valid.
    function importText(text) {
        let r = null
        try {
            r = Schema.load(text)
        } catch (e) {
            return { ok: false, applied: 0, rejected: [], error: "Not a settings file: " + e.message }
        }
        if (r.newer) return { ok: false, applied: 0, rejected: [], error: "This file was written by a newer Levish and cannot be imported." }
        const pairs = []
        for (const path of schemaPaths) {
            if (Schema.rawFor(r.doc, path) !== undefined) pairs.push([path, r.values[path]])
        }
        const rejectedWrites = setMany(pairs)
        return { ok: true, applied: pairs.length - rejectedWrites.length, rejected: r.rejected, error: "" }
    }

    // Applies a named palette preset (every key it lists). Returns false for an unknown name.
    function applyPreset(name) {
        const p = Schema.presets[name]
        if (!p) return false
        setMany(Object.keys(p).map(k => [k, p[k]]))
        return true
    }
    readonly property var presetNames: Object.keys(Schema.presets)

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
        configFile.setText(Schema.serialize(next))
        if (status !== "ok") { status = "ok"; statusDetail = "" }
    }

    // ── Presets for the accent swatches (kept deliberately small) ────────────
    readonly property var accentSwatches: [
        { name: "Aqua",     hex: Palette.accent },
        { name: "Turquoise", hex: "#2dd4bf" },
        { name: "Cyan",     hex: "#38bdf8" },
        { name: "Blue",     hex: "#60a5fa" },
        { name: "Purple",   hex: "#a78bfa" },
        { name: "Green",    hex: "#34d399" },
        { name: "Orange",   hex: "#fb923c" },
        { name: "Red",      hex: "#f87171" }
    ]
}
