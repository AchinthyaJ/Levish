"""Application discovery by scanning .desktop files."""
import asyncio
import configparser
import logging
import os
import re
import shutil
import subprocess
from pathlib import Path
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)

DESKTOP_DIRS = [
    Path.home() / ".local/share/applications",
    Path("/usr/share/applications"),
    Path("/usr/local/share/applications"),
]

# Field codes to strip from Exec=
_FIELD_CODE_RE = re.compile(r"%[uUfFdDnNiIcCkvmBb]")


def _strip_field_codes(exec_str: str) -> str:
    return _FIELD_CODE_RE.sub("", exec_str).strip()


def _try_exec_exists(try_exec: str) -> bool:
    if not try_exec:
        return True
    return shutil.which(try_exec) is not None


class ApplicationManager:
    """Discover, search and launch desktop applications."""

    def __init__(self, event_bus=None, pinned_apps=None) -> None:
        self._bus = event_bus
        self._pinned = pinned_apps
        self._apps: List[Dict[str, Any]] = []
        self._mtimes: Dict[str, float] = {}
        self._lock = asyncio.Lock()

    async def _ensure_loaded(self) -> None:
        """Load apps if cache is stale."""
        if self._is_stale():
            await self._scan()

    def _is_stale(self) -> bool:
        for d in DESKTOP_DIRS:
            if not d.exists():
                continue
            mtime = d.stat().st_mtime
            if self._mtimes.get(str(d), 0) != mtime:
                return True
        return not self._apps

    async def _scan(self) -> None:
        loop = asyncio.get_event_loop()
        apps = await loop.run_in_executor(None, self._scan_sync)
        async with self._lock:
            self._apps = apps
            for d in DESKTOP_DIRS:
                if d.exists():
                    self._mtimes[str(d)] = d.stat().st_mtime
        logger.info("ApplicationManager: loaded %d apps", len(apps))

    def _scan_sync(self) -> List[Dict[str, Any]]:
        seen_names: set = set()
        apps = []
        for directory in DESKTOP_DIRS:
            if not directory.exists():
                continue
            for path in sorted(directory.glob("*.desktop")):
                try:
                    app = self._parse_desktop(path)
                    if app is None:
                        continue
                    key = app["name"].lower()
                    if key in seen_names:
                        continue
                    seen_names.add(key)
                    apps.append(app)
                except Exception as exc:
                    logger.debug("Failed to parse %s: %s", path, exc)
        return sorted(apps, key=lambda a: a["name"].lower())

    def _parse_desktop(self, path: Path) -> Optional[Dict[str, Any]]:
        parser = configparser.RawConfigParser(strict=False)
        parser.read(str(path), encoding="utf-8")

        section = "Desktop Entry"
        if not parser.has_section(section):
            return None

        def get(key: str, fallback: str = "") -> str:
            return parser.get(section, key, fallback=fallback)

        name = get("Name")
        if not name:
            return None

        no_display = get("NoDisplay", "false").lower() == "true"
        hidden = get("Hidden", "false").lower() == "true"
        if no_display or hidden:
            return None

        try_exec = get("TryExec", "")
        if try_exec and not _try_exec_exists(try_exec):
            return None

        exec_raw = get("Exec", "")
        exec_clean = _strip_field_codes(exec_raw)

        return {
            "name": name,
            "exec": exec_clean,
            "icon": get("Icon", "application-x-executable"),
            "categories": get("Categories", ""),
            "generic_name": get("GenericName", ""),
            "comment": get("Comment", ""),
            "desktop_file": str(path),
            "startup_wm_class": get("StartupWMClass", ""),
        }

    async def get_apps(self) -> List[Dict[str, Any]]:
        """Return all discovered apps, sorted by name."""
        await self._ensure_loaded()
        async with self._lock:
            return list(self._apps)

    async def search(self, query: str) -> List[Dict[str, Any]]:
        """Filter apps by name or category (case-insensitive)."""
        await self._ensure_loaded()
        q = query.lower()
        async with self._lock:
            return [
                a for a in self._apps
                if q in a["name"].lower()
                or q in a.get("categories", "").lower()
                or q in a.get("generic_name", "").lower()
                or q in a.get("comment", "").lower()
            ]

    async def launch(self, exec_string: str) -> bool:
        """Launch an application, detached from the parent process."""
        try:
            # Use shell=False for safety; handle shell notation
            args = exec_string.split()
            proc = subprocess.Popen(
                args,
                start_new_session=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            logger.info("ApplicationManager: launched pid=%d cmd=%s", proc.pid, exec_string)
            return True
        except FileNotFoundError:
            # Try via shell
            try:
                proc = subprocess.Popen(
                    exec_string,
                    shell=True,
                    start_new_session=True,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
                logger.info("ApplicationManager: launched (shell) pid=%d", proc.pid)
                return True
            except Exception as exc:
                logger.error("ApplicationManager: launch failed: %s", exc)
                return False
        except Exception as exc:
            logger.error("ApplicationManager: launch failed: %s", exc)
            return False

    async def get_pinned_dock(self) -> List[Dict[str, Any]]:
        """Return pinned dock apps resolved to app dicts."""
        if not self._pinned:
            return []
        pinned_ids = self._pinned.get_dock()
        await self._ensure_loaded()
        async with self._lock:
            name_map = {a["name"].lower(): a for a in self._apps}
            file_map = {a["desktop_file"]: a for a in self._apps}
        result = []
        for pid in pinned_ids:
            if pid in file_map:
                result.append(file_map[pid])
            elif pid.lower() in name_map:
                result.append(name_map[pid.lower()])
        return result

    async def get_pinned_launcher(self) -> List[Dict[str, Any]]:
        """Return pinned launcher apps."""
        if not self._pinned:
            return []
        pinned_ids = self._pinned.get_launcher_pinned()
        await self._ensure_loaded()
        async with self._lock:
            name_map = {a["name"].lower(): a for a in self._apps}
            file_map = {a["desktop_file"]: a for a in self._apps}
        result = []
        for pid in pinned_ids:
            if pid in file_map:
                result.append(file_map[pid])
            elif pid.lower() in name_map:
                result.append(name_map[pid.lower()])
        return result

    async def track_recent(self, desktop_file: str) -> None:
        """Add a launched app to the recent list."""
        if self._pinned:
            self._pinned.add_recent(desktop_file)
