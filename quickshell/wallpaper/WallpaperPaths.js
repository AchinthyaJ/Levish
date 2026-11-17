// Shared wallpaper discovery and hyprpaper helpers.
//
// Everything that reaches a shell is passed as a positional argument ("$1", "$@"), never
// spliced into the script text. A folder name containing quotes, spaces or $(...) is then
// just data.
.pragma library

// Directories scanned for wallpapers. Only generic locations: no user project paths.
function scanRoots(home, xdgPictures, customFolder) {
    const roots = ["/usr/share/hypr", "/usr/share/backgrounds", "/usr/share/wallpapers"]
    const pictures = xdgPictures && xdgPictures !== "" ? xdgPictures : (home + "/Pictures")
    roots.push(pictures)
    if (customFolder && customFolder !== "") roots.push(customFolder)
    return roots.filter((r, i) => roots.indexOf(r) === i)
}

// argv that lists image files under the given roots, one per line, capped at 120.
function scanCommand(roots) {
    return ["sh", "-c",
        'find "$@" -maxdepth 3 -type f \\( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \\) 2>/dev/null | sort -u | head -n 120',
        "sh"].concat(roots)
}

// Directory for Levish-owned state. hyprpaper gets its own config here, never ~/.config/hypr.
function stateDir(xdgState, home) {
    const base = xdgState && xdgState !== "" ? xdgState : (home + "/.local/state")
    return base + "/levish"
}

// argv that writes a hyprpaper config for one image and restarts hyprpaper with it.
// $1 = image path, $2 = fit mode, $3 = config file, $4 = log file.
// Builds the hyprpaper config text. `entries` is [{ monitor, path }]; an empty monitor name means
// every monitor. Entries are written in order, so the general wallpaper comes first and per-monitor
// overrides after it.
function confText(entries, fitMode) {
    // ThemeStore calls this mode "stretch"; hyprpaper spells it "fill".
    const fit = fitMode === "stretch" ? "fill" : fitMode
    let out = ""
    for (const e of entries) {
        out += "wallpaper {\n    monitor = " + (e.monitor || "") + "\n    path = " + e.path + "\n    fit_mode = " + fit + "\n}\n\n"
    }
    return out + "splash = false\n"
}

// Parses "DP-1=/a.png;HDMI-A-1=/b.png" into [{ monitor, path }]. Blank or malformed items are skipped.
function parseMonitors(text) {
    const out = []
    for (const item of String(text || "").split(";")) {
        const i = item.indexOf("=")
        if (i <= 0) continue
        const monitor = item.substring(0, i).trim()
        const path = item.substring(i + 1).trim()
        if (monitor.length && path.length) out.push({ monitor: monitor, path: path })
    }
    return out
}

function applyCommand(entries, fitMode, confFile, logFile) {
    const conf = confText(entries, fitMode)
    const script =
        'mkdir -p "$(dirname "$2")" && '
        + 'printf "%s" "$1" > "$2" && '
        + 'pkill -x hyprpaper 2>/dev/null; sleep 0.15; '
        + 'setsid hyprpaper -c "$2" >"$3" 2>&1 &'
    return ["sh", "-c", script, "sh", conf, confFile, logFile]
}

var FIT_MODES = ["cover", "contain", "stretch", "tile"]
