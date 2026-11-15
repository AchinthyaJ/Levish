import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: store

    readonly property string projectDir: {
        const d = String(Quickshell.shellDir).replace(/^file:\/\//, "").replace(/\/+$/, "")
        return d.substring(0, d.lastIndexOf("/"))
    }

    // ── Reactive Visual Settings ───────────────────────────────────────
    property string accentColor: "#c8f7ef"
    property real glassOpacity: 0.85
    readonly property color glassColor: Qt.rgba(0.08, 0.12, 0.16, glassOpacity)
    readonly property color glassEdge: Qt.rgba(1.0, 1.0, 1.0, 0.20)
    readonly property color dockGlass: Qt.rgba(0.06, 0.08, 0.10, glassOpacity)
    property int cornerRadius: 16
    property string fontFamily: "JetBrains Mono"

    // ── Top Bar Settings ──────────────────────────────────────────────
    property int barHeight: 38
    property string clockFormat: "HH:mm"
    property bool showDate: true
    property bool showSeconds: false
    property int workspaceFocusedWidth: 40
    property int workspaceHeight: 14
    property int workspaceRadius: 7

    // ── Dock Settings ─────────────────────────────────────────────────
    property bool dockEnabled: true
    property int dockIconSize: 48
    property bool dockAutoHide: false
    property int dockMargin: 10
    property string dockMonitor: ""

    // ── Launcher Settings ─────────────────────────────────────────────
    property string launcherDefaultView: "grid"
    property int launcherColumns: 5

    // ── Performance & System Settings ─────────────────────────────────
    property real metricsInterval: 2.0
    property bool showGpu: true
    property bool showTemp: true

    property string currentPreset: "Levish Aqua"
    property var fullConfig: ({})

    // Presets definitions
    readonly property var presets: [
        {
            name: "Levish Aqua (Default)",
            accent: "#c8f7ef",
            opacity: 0.85,
            radius: 16,
            barHeight: 38,
            dockIconSize: 48
        },
        {
            name: "Tokyo Night",
            accent: "#7aa2f7",
            opacity: 0.90,
            radius: 14,
            barHeight: 38,
            dockIconSize: 48
        },
        {
            name: "Cyberpunk Neon",
            accent: "#00ff9f",
            opacity: 0.92,
            radius: 8,
            barHeight: 36,
            dockIconSize: 52
        },
        {
            name: "Catppuccin Mocha",
            accent: "#cba6f7",
            opacity: 0.88,
            radius: 18,
            barHeight: 40,
            dockIconSize: 48
        },
        {
            name: "Dracula Rose",
            accent: "#ff79c6",
            opacity: 0.85,
            radius: 14,
            barHeight: 38,
            dockIconSize: 48
        },
        {
            name: "Nord Glacier",
            accent: "#88c0d0",
            opacity: 0.88,
            radius: 12,
            barHeight: 36,
            dockIconSize: 46
        },
        {
            name: "Sunset Amber",
            accent: "#f59e0b",
            opacity: 0.86,
            radius: 16,
            barHeight: 38,
            dockIconSize: 48
        }
    ]

    function loadConfig(raw) {
        try {
            const c = JSON.parse(raw)
            store.fullConfig = c

            if (c.theme) {
                if (c.theme.accent) store.accentColor = c.theme.accent
                if (c.theme.opacity !== undefined) store.glassOpacity = Math.max(0.3, Math.min(1.0, Number(c.theme.opacity)))
                if (c.theme.radius !== undefined) store.cornerRadius = Math.max(4, Math.min(28, Number(c.theme.radius)))
                if (c.theme.preset) store.currentPreset = c.theme.preset
            }
            if (c.bar) {
                if (c.bar.height) store.barHeight = Math.max(28, Math.min(60, Number(c.bar.height)))
                if (c.bar.clock_format) store.clockFormat = c.bar.clock_format
                if (c.bar.show_date !== undefined) store.showDate = c.bar.show_date
                if (c.bar.show_seconds !== undefined) store.showSeconds = c.bar.show_seconds
                if (c.bar.ws_width) store.workspaceFocusedWidth = Math.max(20, Math.min(64, Number(c.bar.ws_width)))
                if (c.bar.ws_height) store.workspaceHeight = Math.max(8, Math.min(24, Number(c.bar.ws_height)))
                if (c.bar.ws_radius) store.workspaceRadius = Math.max(3, Math.min(12, Number(c.bar.ws_radius)))
            }
            if (c.dock) {
                if (c.dock.enabled !== undefined) store.dockEnabled = c.dock.enabled
                if (c.dock.icon_size) store.dockIconSize = Math.max(24, Math.min(96, Number(c.dock.icon_size)))
                if (c.dock.auto_hide !== undefined) store.dockAutoHide = c.dock.auto_hide === true
                if (c.dock.margin !== undefined) store.dockMargin = Math.max(0, Math.min(100, Number(c.dock.margin)))
                if (c.dock.monitor) store.dockMonitor = String(c.dock.monitor)
            }
            if (c.launcher) {
                if (c.launcher.default_view) store.launcherDefaultView = c.launcher.default_view
                if (c.launcher.columns) store.launcherColumns = Math.max(3, Math.min(8, Number(c.launcher.columns)))
            }
            if (c.metrics_interval) store.metricsInterval = Number(c.metrics_interval)
        } catch (e) {
            console.warn("ThemeStore: error loading config: " + e)
        }
    }

    function saveSetting(section, key, value) {
        // Update memory immediately for instantaneous reaction
        if (section === "theme") {
            if (key === "accent") store.accentColor = value
            else if (key === "opacity") store.glassOpacity = value
            else if (key === "radius") store.cornerRadius = value
        } else if (section === "bar") {
            if (key === "height") store.barHeight = value
            else if (key === "clock_format") store.clockFormat = value
            else if (key === "show_date") store.showDate = value
            else if (key === "show_seconds") store.showSeconds = value
            else if (key === "ws_width") store.workspaceFocusedWidth = value
            else if (key === "ws_height") store.workspaceHeight = value
            else if (key === "ws_radius") store.workspaceRadius = value
        } else if (section === "dock") {
            if (key === "enabled") store.dockEnabled = value
            else if (key === "icon_size") store.dockIconSize = value
            else if (key === "auto_hide") store.dockAutoHide = value
            else if (key === "margin") store.dockMargin = value
            else if (key === "monitor") store.dockMonitor = value
        } else if (section === "launcher") {
            if (key === "default_view") store.launcherDefaultView = value
            else if (key === "columns") store.launcherColumns = value
        } else if (key === "metrics_interval") {
            store.metricsInterval = value
        }

        // Persist to disk
        const c = Object.assign({}, store.fullConfig)
        if (section) {
            c[section] = Object.assign({}, c[section] || {})
            c[section][key] = value
        } else {
            c[key] = value
        }
        store.fullConfig = c
        configFile.setText(JSON.stringify(c, null, 2) + "\n")
    }

    function applyPreset(p) {
        store.currentPreset = p.name
        store.accentColor = p.accent
        store.glassOpacity = p.opacity
        store.cornerRadius = p.radius
        store.barHeight = p.barHeight
        store.dockIconSize = p.dockIconSize

        const c = Object.assign({}, store.fullConfig)
        c.theme = Object.assign({}, c.theme || {}, {
            accent: p.accent,
            opacity: p.opacity,
            radius: p.radius,
            preset: p.name
        })
        c.bar = Object.assign({}, c.bar || {}, { height: p.barHeight })
        c.dock = Object.assign({}, c.dock || {}, { icon_size: p.dockIconSize })
        store.fullConfig = c
        configFile.setText(JSON.stringify(c, null, 2) + "\n")
    }

    function resetToDefaults() {
        applyPreset(store.presets[0])
        saveSetting("bar", "clock_format", "HH:mm")
        saveSetting("bar", "show_date", true)
        saveSetting("bar", "ws_width", 40)
        saveSetting("bar", "ws_height", 14)
        saveSetting("bar", "ws_radius", 7)
        saveSetting("dock", "enabled", true)
        saveSetting("dock", "auto_hide", false)
        saveSetting("dock", "margin", 10)
        saveSetting("launcher", "default_view", "grid")
        saveSetting("launcher", "columns", 5)
    }

    FileView {
        id: configFile
        path: store.projectDir + "/config/config.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: store.loadConfig(text())
    }
}
