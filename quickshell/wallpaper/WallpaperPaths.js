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
function applyCommand(imagePath, fitMode, confFile, logFile) {
    const script =
        'mkdir -p "$(dirname "$3")" && '
        + 'printf "wallpaper {\\n    monitor =\\n    path = %s\\n    fit_mode = %s\\n}\\n\\nsplash = false\\n" "$1" "$2" > "$3" && '
        + 'pkill -x hyprpaper 2>/dev/null; sleep 0.15; '
        + 'setsid hyprpaper -c "$3" >"$4" 2>&1 &'
    // ThemeStore calls this mode "stretch"; hyprpaper spells it "fill".
    const fit = fitMode === "stretch" ? "fill" : fitMode
    return ["sh", "-c", script, "sh", imagePath, fit, confFile, logFile]
}

var FIT_MODES = ["cover", "contain", "stretch", "tile"]
