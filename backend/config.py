"""Levish configuration manager."""
import json
import os
import threading
from pathlib import Path
from typing import Any, Dict, List, Optional

PROJECT_ROOT = Path(__file__).parent.parent
CONFIG_DIR = PROJECT_ROOT / "config"
STATE_DIR = Path("/tmp/levish")

DEFAULTS: Dict[str, Any] = {
    "theme": {
        "bg_primary": "#1a1a2e",
        "bg_secondary": "#16213e",
        "bg_tertiary": "#0f3460",
        "accent": "#e94560",
        "accent_secondary": "#533483",
        "text_primary": "#eaeaea",
        "text_secondary": "#a0a0b0",
        "text_muted": "#606070",
        "font_size": 13,
        "radius": 12,
    },
    "bar": {"height": 42, "margin": 10, "padding_h": 14},
    "dock": {"icon_size": 48, "auto_hide": False, "position": "bottom", "margin": 10},
    "osd": {"timeout_ms": 2500, "position": "bottom-center"},
    "metrics_interval": 2,
    "clock_format": "%H:%M",
    "date_format": "%a %d",
    "monitor": "eDP-1",
}


def _deep_merge(base: dict, override: dict) -> dict:
    """Deep-merge override into base, returning a new dict."""
    result = dict(base)
    for key, value in override.items():
        if key in result and isinstance(result[key], dict) and isinstance(value, dict):
            result[key] = _deep_merge(result[key], value)
        else:
            result[key] = value
    return result


class Config:
    """Thread-safe configuration manager with deep-merge defaults."""

    CONFIG_FILE = CONFIG_DIR / "config.json"

    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._data: Dict[str, Any] = {}
        CONFIG_DIR.mkdir(parents=True, exist_ok=True)
        self.reload()

    def reload(self) -> None:
        """Load config from disk and merge with defaults."""
        loaded: Dict[str, Any] = {}
        if self.CONFIG_FILE.exists():
            try:
                with open(self.CONFIG_FILE, "r", encoding="utf-8") as f:
                    loaded = json.load(f)
            except (json.JSONDecodeError, OSError) as exc:
                print(f"[config] Warning: failed to load config: {exc}")
        with self._lock:
            self._data = _deep_merge(DEFAULTS, loaded)

    def get(self, key: str, default: Any = None) -> Any:
        """Get a config value by dot-separated key path."""
        with self._lock:
            parts = key.split(".")
            node: Any = self._data
            for part in parts:
                if isinstance(node, dict) and part in node:
                    node = node[part]
                else:
                    return default
            return node

    def set(self, key: str, value: Any) -> None:
        """Set a config value by dot-separated key path and save."""
        with self._lock:
            parts = key.split(".")
            node = self._data
            for part in parts[:-1]:
                node = node.setdefault(part, {})
            node[parts[-1]] = value
        self.save()

    def save(self) -> None:
        """Persist current config to disk."""
        CONFIG_DIR.mkdir(parents=True, exist_ok=True)
        try:
            with self._lock:
                data = dict(self._data)
            with open(self.CONFIG_FILE, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2)
        except OSError as exc:
            print(f"[config] Warning: failed to save config: {exc}")

    def all(self) -> Dict[str, Any]:
        """Return a copy of the full config dict."""
        with self._lock:
            return dict(self._data)


PINNED_APPS_FILE = CONFIG_DIR / "pinned-apps.json"

_PINNED_DEFAULTS: Dict[str, Any] = {
    "dock": [],
    "launcher_pinned": [],
    "recent": [],
}


class PinnedApps:
    """Load/save pinned and recent app lists from config/pinned-apps.json."""

    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._data: Dict[str, Any] = {}
        CONFIG_DIR.mkdir(parents=True, exist_ok=True)
        self._load()

    def _load(self) -> None:
        loaded: Dict[str, Any] = {}
        if PINNED_APPS_FILE.exists():
            try:
                with open(PINNED_APPS_FILE, "r", encoding="utf-8") as f:
                    loaded = json.load(f)
            except (json.JSONDecodeError, OSError) as exc:
                print(f"[config] Warning: failed to load pinned apps: {exc}")
        with self._lock:
            self._data = _deep_merge(_PINNED_DEFAULTS, loaded)

    def save(self) -> None:
        CONFIG_DIR.mkdir(parents=True, exist_ok=True)
        try:
            with self._lock:
                data = dict(self._data)
            with open(PINNED_APPS_FILE, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2)
        except OSError as exc:
            print(f"[config] Warning: failed to save pinned apps: {exc}")

    def get_dock(self) -> List[str]:
        with self._lock:
            return list(self._data.get("dock", []))

    def set_dock(self, apps: List[str]) -> None:
        with self._lock:
            self._data["dock"] = list(apps)
        self.save()

    def get_launcher_pinned(self) -> List[str]:
        with self._lock:
            return list(self._data.get("launcher_pinned", []))

    def set_launcher_pinned(self, apps: List[str]) -> None:
        with self._lock:
            self._data["launcher_pinned"] = list(apps)
        self.save()

    def get_recent(self) -> List[str]:
        with self._lock:
            return list(self._data.get("recent", []))

    def add_recent(self, app_id: str, max_items: int = 10) -> None:
        with self._lock:
            recent: List[str] = list(self._data.get("recent", []))
            if app_id in recent:
                recent.remove(app_id)
            recent.insert(0, app_id)
            self._data["recent"] = recent[:max_items]
        self.save()
