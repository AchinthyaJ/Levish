#!/usr/bin/env python3
"""
Application list for Levish launcher.
Scans .desktop files, optionally filters by query arg.
"""
import json
import os
import sys
import re
from pathlib import Path
from configparser import ConfigParser

DESKTOP_DIRS = [
    Path.home() / ".local/share/applications",
    Path("/usr/share/applications"),
]

ICON_DIRS = [
    Path.home() / ".local/share/icons",
    Path("/usr/share/icons/hicolor"),
    Path("/usr/share/icons/Papirus"),
    Path("/usr/share/icons/breeze"),
    Path("/usr/share/pixmaps"),
]
ICON_SIZES = ["48x48", "64x64", "32x32", "scalable", "128x128", "24x24"]
ICON_EXTS  = [".svg", ".png", ".xpm"]
FALLBACK   = ""


def find_icon(name: str) -> str:
    if not name:
        return FALLBACK
    if os.path.isabs(name) and os.path.exists(name):
        return name

    for icon_dir in ICON_DIRS:
        if not icon_dir.exists():
            continue
        for size in ICON_SIZES:
            for category in ["apps", "devices", "places", ""]:
                base = icon_dir / size / category if category else icon_dir / size
                for ext in ICON_EXTS:
                    p = base / f"{name}{ext}"
                    if p.exists():
                        return str(p)

    for ext in ICON_EXTS:
        p = Path("/usr/share/pixmaps") / f"{name}{ext}"
        if p.exists():
            return str(p)

    return FALLBACK


def scan_apps(query: str = "") -> list[dict]:
    apps: dict[str, dict] = {}
    query_lower = query.lower()

    for d in DESKTOP_DIRS:
        if not d.exists():
            continue
        for f in sorted(d.glob("*.desktop")):
            try:
                cfg = ConfigParser(interpolation=None, strict=False)
                cfg.read(str(f), encoding="utf-8")
                if "Desktop Entry" not in cfg:
                    continue
                entry = cfg["Desktop Entry"]
                if entry.get("NoDisplay", "false").lower() == "true":
                    continue
                if entry.get("Hidden", "false").lower() == "true":
                    continue
                if entry.get("Type", "") != "Application":
                    continue

                name       = entry.get("Name", "")
                exec_raw   = entry.get("Exec", "")
                icon       = entry.get("Icon", "")
                categories = entry.get("Categories", "")

                if not name or not exec_raw:
                    continue

                exec_clean = re.sub(r"%[uUfFdDnNiIcCkvmBb]", "", exec_raw).strip()

                if query_lower and query_lower not in name.lower() and query_lower not in categories.lower():
                    continue

                key = f.stem.lower()
                if key not in apps:
                    apps[key] = {
                        "name": name,
                        "exec": exec_clean,
                        "icon": find_icon(icon),
                        "categories": categories,
                        "desktop_file": str(f),
                    }
            except Exception:
                continue

    return sorted(apps.values(), key=lambda x: x["name"].lower())


def main():
    query = ""
    if len(sys.argv) > 2 and sys.argv[1] == "--query":
        query = sys.argv[2]
    elif len(sys.argv) > 1:
        query = sys.argv[1]

    apps = scan_apps(query)
    print(json.dumps(apps))


if __name__ == "__main__":
    main()
