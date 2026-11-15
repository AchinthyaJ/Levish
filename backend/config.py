"""Levish backend configuration.

Ownership: the QML ThemeStore (quickshell/common/ThemeStore.qml) is the single owner of
config/config.json. It validates and writes every appearance, bar, dock, launcher and
wallpaper key. This module reads the same file but only the keys the Python backend itself
consumes, so the two sides can no longer disagree about defaults.

Keys owned by the backend:
  metrics_interval   seconds between system metric samples
"""
import json
import threading
from pathlib import Path
from typing import Any, Dict, List, Optional

PROJECT_ROOT = Path(__file__).parent.parent
CONFIG_DIR = PROJECT_ROOT / "config"
STATE_DIR = Path("/tmp/levish")

# Only backend-owned keys. Theme, bar, dock and wallpaper defaults live in ThemeStore.qml.
DEFAULTS: Dict[str, Any] = {
    "metrics_interval": 2,
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
    """Thread-safe reader for config.json, merged over backend defaults.

    `path` defaults to config/config.json. Tests pass a temporary path so they never touch
    the user's live configuration.
    """

    def __init__(self, path: Optional[Path] = None) -> None:
        self.path = Path(path) if path is not None else CONFIG_DIR / "config.json"
        self._lock = threading.Lock()
        self._data: Dict[str, Any] = {}
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.reload()

    def reload(self) -> None:
        """Load config from disk and merge with defaults."""
        loaded: Dict[str, Any] = {}
        if self.path.exists():
            try:
                with open(self.path, "r", encoding="utf-8") as f:
                    loaded = json.load(f)
                if not isinstance(loaded, dict):
                    raise ValueError("root is not an object")
            except (json.JSONDecodeError, OSError, ValueError) as exc:
                print(f"[config] Warning: failed to load config, using defaults: {exc}")
                loaded = {}
        with self._lock:
            self._data = _deep_merge(DEFAULTS, loaded)

    def get(self, key: str, default: Any = None) -> Any:
        """Get a config value by dot-separated key path."""
        with self._lock:
            node: Any = self._data
            for part in key.split("."):
                if isinstance(node, dict) and part in node:
                    node = node[part]
                else:
                    return default
            return node

    def set(self, key: str, value: Any) -> None:
        """Set a config value by dot-separated key path and save.

        Writes only through this method for backend-owned keys. Settings UI values must go
        through ThemeStore.
        """
        with self._lock:
            parts = key.split(".")
            node = self._data
            for part in parts[:-1]:
                node = node.setdefault(part, {})
            node[parts[-1]] = value
        self.save()

    def save(self) -> None:
        """Persist current config to disk atomically (write temp file, then replace)."""
        self.path.parent.mkdir(parents=True, exist_ok=True)
        try:
            with self._lock:
                data = json.loads(json.dumps(self._data))
            tmp = self.path.with_suffix(self.path.suffix + ".tmp")
            with open(tmp, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2)
            tmp.replace(self.path)
        except OSError as exc:
            print(f"[config] Warning: failed to save config: {exc}")

    def all(self) -> Dict[str, Any]:
        """Return a copy of the full config dict."""
        with self._lock:
            return json.loads(json.dumps(self._data))


_PINNED_DEFAULTS: Dict[str, Any] = {
    "dock": [],
    "launcher_pinned": [],
    "recent": [],
}


class PinnedApps:
    """Load/save pinned and recent app lists from config/pinned-apps.json."""

    def __init__(self, path: Optional[Path] = None) -> None:
        self.path = Path(path) if path is not None else CONFIG_DIR / "pinned-apps.json"
        self._lock = threading.Lock()
        self._data: Dict[str, Any] = {}
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self._load()

    def _load(self) -> None:
        loaded: Dict[str, Any] = {}
        if self.path.exists():
            try:
                with open(self.path, "r", encoding="utf-8") as f:
                    loaded = json.load(f)
                if not isinstance(loaded, dict):
                    raise ValueError("root is not an object")
            except (json.JSONDecodeError, OSError, ValueError) as exc:
                print(f"[config] Warning: failed to load pinned apps: {exc}")
                loaded = {}
        with self._lock:
            self._data = _deep_merge(_PINNED_DEFAULTS, loaded)

    def save(self) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        try:
            with self._lock:
                data = json.loads(json.dumps(self._data))
            tmp = self.path.with_suffix(self.path.suffix + ".tmp")
            with open(tmp, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2)
            tmp.replace(self.path)
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
