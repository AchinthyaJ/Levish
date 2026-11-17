// Levish configuration schema and validation. Pure JavaScript with no Qt dependency, so the same
// rules run in the shell (ThemeStore.qml) and in unit tests (tests/config_schema.test.js).
//
// Every persisted key is declared here once: its live property name (`prop`), its kind, its
// default and its bounds. Invalid values never reach the UI; they fall back to the default.

var CONFIG_VERSION = 1

var schema = {
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
    "lock.disable_widgets": { prop: "lockDisableWidgets",   kind: "bool",  def: false },
    "bar.show_perf":        { prop: "showPerf",              kind: "bool",  def: true },
    "bar.show_workspaces":  { prop: "showWorkspaces",        kind: "bool",  def: true },
    "bar.show_window_title":{ prop: "showWindowTitle",       kind: "bool",  def: true },
    "bar.show_clock":       { prop: "showClock",             kind: "bool",  def: true },
    "bar.show_status":      { prop: "showStatus",            kind: "bool",  def: true },
    "bar.show_tray":        { prop: "showTray",              kind: "bool",  def: true },
    "dock.spacing":         { prop: "dockSpacing",           kind: "int",   def: 4, min: 0, max: 24 },
    "dock.zoom":            { prop: "dockZoom",              kind: "real",  def: 1.12, min: 1.0, max: 1.5 },
    "bar.position":         { prop: "barPosition",          kind: "enum",  def: "top", choices: ["top", "bottom"] },
    "bar.gap":              { prop: "barGap",               kind: "int",   def: 0, min: 0, max: 60 },
    "bar.side_margin":      { prop: "barSideMargin",         kind: "int",   def: 0, min: 0, max: 200 },
    "bar.radius":           { prop: "barRadius",             kind: "int",   def: 0, min: 0, max: 24 },
    "bar.border":           { prop: "barBorder",             kind: "real",  def: 0.0, min: 0.0, max: 1.0 },
    "theme.border":         { prop: "borderStrength",        kind: "real",  def: 0.2, min: 0.0, max: 1.0 },
    "dock.shadow":          { prop: "dockShadow",            kind: "real",  def: 1.0, min: 0.0, max: 1.0 },
    "theme.font_scale":     { prop: "fontScale",            kind: "real",  def: 1.0, min: 0.8, max: 1.4 },
    "launcher.icon_size":   { prop: "launcherIconSize",      kind: "int",   def: 42, min: 24, max: 72 },
    "launcher.sort":        { prop: "launcherSort",          kind: "enum",  def: "name", choices: ["name", "pinned_first"] },
    "launcher.hidden":      { prop: "launcherHidden",        kind: "string", def: "", max: 4096 },
    "wallpaper.monitors":   { prop: "wallpaperMonitors",     kind: "string", def: "", max: 4096 },
    "dock.position":        { prop: "dockPosition",         kind: "enum",  def: "bottom", choices: ["bottom", "top", "left", "right"] },
    "palette.window": { prop: "paletteWindow", kind: "color", def: "#14161c" },
    "palette.sidebar": { prop: "paletteSidebar", kind: "color", def: "#0f1116" },
    "palette.bar": { prop: "paletteBar", kind: "color", def: "#16262e" },
    "palette.dock": { prop: "paletteDock", kind: "color", def: "#111316" },
    "palette.text": { prop: "paletteText", kind: "color", def: "#f5f9fd" },
    "palette.text_secondary": { prop: "paletteTextSecondary", kind: "color", def: "#c9d6e8" },
    "palette.muted": { prop: "paletteMuted", kind: "color", def: "#9fb0c6" },
    "palette.ink": { prop: "paletteInk", kind: "color", def: "#ffffff" },
    "palette.icon_tile": { prop: "paletteIconTile", kind: "color", def: "#1f2a33" },
    "palette.ok": { prop: "paletteOk", kind: "color", def: "#34d399" },
    "palette.warning": { prop: "paletteWarning", kind: "color", def: "#fb923c" },
    "palette.danger": { prop: "paletteDanger", kind: "color", def: "#f0708a" },
    "ui.reduced_motion":    { prop: "reducedMotion",        kind: "bool",  def: false },
    "settings.last_page":   { prop: "settingsLastPage",     kind: "enum",  def: "overview", choices: ["overview", "appearance", "topbar", "dock", "launcher", "wallpaper", "notifications", "osd", "clipboard", "keyboard", "displays", "session", "lock", "about"] }
    }

function schemaPaths() { return Object.keys(schema) }

// Complete colour palettes. Applying one sets every key listed. Values are checked by the tests.
var presets = {
    "Levish Aqua": {
        "theme.accent": "#c8f7ef", "palette.window": "#14161c", "palette.sidebar": "#0f1116",
        "palette.bar": "#16262e", "palette.dock": "#111316", "palette.text": "#f5f9fd",
        "palette.text_secondary": "#c9d6e8", "palette.muted": "#9fb0c6", "palette.ink": "#ffffff",
        "palette.icon_tile": "#1f2a33", "palette.ok": "#34d399", "palette.warning": "#fb923c", "palette.danger": "#f0708a"
    },
    "Midnight": {
        "theme.accent": "#7aa2f7", "palette.window": "#0b0d14", "palette.sidebar": "#07080c",
        "palette.bar": "#101a2e", "palette.dock": "#0c1220", "palette.text": "#e6edf7",
        "palette.text_secondary": "#aab8cc", "palette.muted": "#7d8ca3", "palette.ink": "#ffffff",
        "palette.icon_tile": "#17213a", "palette.ok": "#34d399", "palette.warning": "#fb923c", "palette.danger": "#f0708a"
    },
    "Light": {
        "theme.accent": "#0e9f8e", "palette.window": "#eef2f6", "palette.sidebar": "#e3e9f0",
        "palette.bar": "#ffffff", "palette.dock": "#ffffff", "palette.text": "#14202e",
        "palette.text_secondary": "#3b4a5e", "palette.muted": "#5f6f83", "palette.ink": "#0b1320",
        "palette.icon_tile": "#dde5ee", "palette.ok": "#15803d", "palette.warning": "#b45309", "palette.danger": "#b91c1c"
    },
    "Warm": {
        "theme.accent": "#fb923c", "palette.window": "#1c1511", "palette.sidebar": "#15100c",
        "palette.bar": "#2a1d16", "palette.dock": "#201611", "palette.text": "#fbeee3",
        "palette.text_secondary": "#e6d3c2", "palette.muted": "#b59c88", "palette.ink": "#ffffff",
        "palette.icon_tile": "#33241b", "palette.ok": "#a3e635", "palette.warning": "#fbbf24", "palette.danger": "#f87171"
    }
};

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

function splitPath(path) {
    const i = path.indexOf(".")
    return i < 0 ? ["", path] : [path.substring(0, i), path.substring(i + 1)]
}

// Reads a schema path from a document.
function rawFor(doc, path) {
    const parts = splitPath(path)
    if (parts[0] === "") return doc[parts[1]]
    return doc[parts[0]] ? doc[parts[0]][parts[1]] : undefined
}

// Writes a schema path into a document, creating the section object when needed.
function writeFor(doc, path, value) {
    const parts = splitPath(path)
    if (parts[0] === "") { doc[parts[1]] = value; return }
    if (typeof doc[parts[0]] !== "object" || doc[parts[0]] === null) doc[parts[0]] = {}
    doc[parts[0]][parts[1]] = value
}

// ── Migrations ─────────────────────────────────────────────────────────────
// migrations[n] upgrades a document from version n to n+1. Unversioned files are version 0.
// Add new entries at the end; never edit an existing one.
var migrations = [
    // 0 -> 1: the legacy top-level "monitor" key becomes dock.monitor when that is empty.
    function (doc) {
        const out = JSON.parse(JSON.stringify(doc))
        if (typeof out.monitor === "string") {
            if (!out.dock || typeof out.dock !== "object") out.dock = {}
            if (out.dock.monitor === undefined || out.dock.monitor === "") out.dock.monitor = out.monitor
            delete out.monitor
        }
        return out
    }
]

// Returns { doc, newer }: the document upgraded to CONFIG_VERSION, and whether it was written by a
// newer Levish (in which case it is returned unchanged, and its keys are not touched).
function migrate(doc) {
    let out = JSON.parse(JSON.stringify(doc))
    const version = typeof out.config_version === "number" ? out.config_version : 0
    if (version > CONFIG_VERSION) return { doc: out, newer: true }
    for (let v = version; v < CONFIG_VERSION; v++) out = migrations[v](out)
    out.config_version = CONFIG_VERSION
    return { doc: out, newer: false }
}

// Validates a migrated document. Returns the accepted values and the paths that were rejected.
// A path missing from the document is not rejected; it takes its default.
function validate(doc) {
    const values = {}
    const rejected = []
    for (const path of schemaPaths()) {
        const entry = schema[path]
        const raw = rawFor(doc, path)
        const v = coerce(entry, raw)
        if (v === undefined) {
            if (raw !== undefined) rejected.push(path)
            values[path] = entry.def
        } else {
            values[path] = v
        }
    }
    return { values: values, rejected: rejected }
}

// Parses text from config.json or an import. Throws on anything that is not a JSON object.
function parseDocument(text) {
    const parsed = JSON.parse(text)
    if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) throw new Error("root is not an object")
    return parsed
}

// Full pipeline for a text document: parse, migrate, validate.
// Returns { doc, values, rejected, newer }.
function load(text) {
    const m = migrate(parseDocument(text))
    const v = validate(m.doc)
    return { doc: m.doc, values: v.values, rejected: v.rejected, newer: m.newer }
}

// Text written to config.json: the document with its version stamped.
function serialize(doc) {
    const out = JSON.parse(JSON.stringify(doc))
    out.config_version = CONFIG_VERSION
    return JSON.stringify(out, null, 2) + "\n"
}
