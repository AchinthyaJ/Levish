#!/usr/bin/env python3
"""
Dock application list for Levish.
Resolves pinned apps, checks running/focused state, resolves icons.
"""
import json
import os
import subprocess
import sys
from pathlib import Path
from configparser import ConfigParser

PROJECT_ROOT = Path(__file__).parent.parent
CONFIG_FILE  = PROJECT_ROOT / "config" / "pinned-apps.json"

ICON_DIRS = [
    Path.home() / ".local/share/icons",
    Path("/usr/share/icons/hicolor"),
    Path("/usr/share/icons/Papirus"),
    Path("/usr/share/icons/breeze"),
    Path("/usr/share/pixmaps"),
]
ICON_SIZES  = ["48x48", "32x32", "64x64", "24x24", "scalable", "128x128"]
ICON_EXTS   = [".svg", ".png", ".xpm"]
FALLBACK_ICON = "/usr/share/pixmaps/default.xpm"

DESKTOP_DIRS = [
    Path.home() / ".local/share/applications",
    Path("/usr/share/applications"),
]


def find_icon(name: str) -> str:
    if not name:
        return FALLBACK_ICON
    if os.path.isabs(name) and os.path.exists(name):
        return name

    # Search hicolor + other icon dirs
    for icon_dir in ICON_DIRS:
        if not icon_dir.exists():
            continue
        for size in ICON_SIZES:
            for category in ["apps", "devices", "places", "mimetypes", ""]:
                base = icon_dir / size / category if category else icon_dir / size
                for ext in ICON_EXTS:
                    p = base / f"{name}{ext}"
                    if p.exists():
                        return str(p)

    # Flat search in pixmaps
    pmap = Path("/usr/share/pixmaps")
    for ext in ICON_EXTS:
        p = pmap / f"{name}{ext}"
        if p.exists():
            return str(p)

    return FALLBACK_ICON


def parse_desktop(path: Path) -> dict | None:
    cfg = ConfigParser(interpolation=None, strict=False)
    try:
        cfg.read(str(path), encoding="utf-8")
    except Exception:
        return None

    if "Desktop Entry" not in cfg:
        return None

    entry = cfg["Desktop Entry"]
    if entry.get("NoDisplay", "false").lower() == "true":
        return None
    if entry.get("Hidden", "false").lower() == "true":
        return None
    if entry.get("Type", "") != "Application":
        return None

    name = entry.get("Name", "")
    exec_raw = entry.get("Exec", "")
    icon = entry.get("Icon", "")

    # Strip field codes from Exec
    import re
    exec_clean = re.sub(r"%[uUfFdDnNiIcCkvmBb]", "", exec_raw).strip()
    exec_clean = exec_clean.split(" -- ")[0].strip()  # strip trailing cruft

    return {
        "name": name,
        "exec": exec_clean,
        "icon_name": icon,
        "desktop_file": str(path),
    }


def get_all_apps() -> dict[str, dict]:
    apps: dict[str, dict] = {}
    for d in DESKTOP_DIRS:
        if not d.exists():
            continue
        for f in sorted(d.glob("*.desktop")):
            app = parse_desktop(f)
            if app and app["name"] and app["exec"]:
                key = f.stem.lower()
                if key not in apps:
                    apps[key] = app
    return apps


def get_running_classes() -> set[str]:
    """Get window classes of running apps via hyprctl."""
    try:
        result = subprocess.run(
            ["hyprctl", "clients", "-j"],
            capture_output=True, text=True, timeout=2
        )
        clients = json.loads(result.stdout or "[]")
        return {c.get("class", "").lower() for c in clients}
    except Exception:
        return set()


def get_focused_class() -> str:
    """Get window class of focused window."""
    try:
        result = subprocess.run(
            ["hyprctl", "activewindow", "-j"],
            capture_output=True, text=True, timeout=2
        )
        win = json.loads(result.stdout or "{}")
        return win.get("class", "").lower()
    except Exception:
        return ""


def main():
    # Load pinned apps list
    try:
        with open(CONFIG_FILE) as f:
            cfg = json.load(f)
        pinned = cfg.get("dock", [])
    except Exception:
        pinned = ["firefox", "thunar", "kitty"]

    all_apps = get_all_apps()
    running  = get_running_classes()
    focused  = get_focused_class()

    output = []
    for app_key in pinned:
        # Try exact match first, then partial
        app = all_apps.get(app_key.lower())
        if not app:
            for k, v in all_apps.items():
                if app_key.lower() in k:
                    app = v
                    break
        if not app:
            app = {
                "name": app_key.capitalize(),
                "exec": app_key,
                "icon_name": app_key,
                "desktop_file": "",
            }

        icon_path = find_icon(app["icon_name"])
        cls = app["exec"].split()[0].split("/")[-1].lower()

        output.append({
            "name": app["name"],
            "icon": icon_path,
            "exec": app["exec"],
            "running": cls in running or app_key.lower() in running,
            "focused": cls == focused or app_key.lower() == focused,
            "desktop_file": app["desktop_file"],
        })

    print(json.dumps(output))


if __name__ == "__main__":
    main()
