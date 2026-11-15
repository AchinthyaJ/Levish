#!/usr/bin/env python3
"""
Unit tests for Levish backend components.
"""
import json
import sys
import tempfile
import unittest
import asyncio
from pathlib import Path

# Add backend directory to path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT / "backend"))

from config import Config, PinnedApps
from events import EventBus
from system.metrics import SystemMetrics
from system.battery import BatteryMonitor
from applications.apps import ApplicationManager
from brightness import BrightnessManager
from power.power import PowerManager


class TestConfig(unittest.TestCase):
    """All tests use a temporary directory; the user's config/ is never read or written."""

    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self._tmp.name)

    def tearDown(self):
        self._tmp.cleanup()

    def test_defaults_when_file_missing(self):
        cfg = Config(self.dir / "config.json")
        self.assertEqual(cfg.get("metrics_interval"), 2)
        # ThemeStore owns these; the backend must not supply defaults for them.
        self.assertIsNone(cfg.get("bar.height"))
        self.assertIsNone(cfg.get("theme.accent"))

    def test_reads_backend_keys_and_ignores_theme_keys(self):
        path = self.dir / "config.json"
        path.write_text(json.dumps({"metrics_interval": 5, "bar": {"height": 36}}))
        cfg = Config(path)
        self.assertEqual(cfg.get("metrics_interval"), 5)
        self.assertEqual(cfg.get("bar.height"), 36)

    def test_invalid_json_falls_back_to_defaults(self):
        path = self.dir / "config.json"
        path.write_text("{not json")
        cfg = Config(path)
        self.assertEqual(cfg.get("metrics_interval"), 2)

    def test_non_object_root_falls_back_to_defaults(self):
        path = self.dir / "config.json"
        path.write_text("[1, 2, 3]")
        cfg = Config(path)
        self.assertEqual(cfg.get("metrics_interval"), 2)

    def test_set_persists_and_preserves_other_keys(self):
        path = self.dir / "config.json"
        path.write_text(json.dumps({"bar": {"height": 36}, "wallpaper": {"fit": "cover"}}))
        cfg = Config(path)
        cfg.set("metrics_interval", 3)
        saved = json.loads(path.read_text())
        self.assertEqual(saved["metrics_interval"], 3)
        self.assertEqual(saved["bar"]["height"], 36)
        self.assertEqual(saved["wallpaper"]["fit"], "cover")
        self.assertFalse((self.dir / "config.json.tmp").exists())

    def test_pinned_apps_roundtrip(self):
        pinned = PinnedApps(self.dir / "pinned-apps.json")
        self.assertEqual(pinned.get_dock(), [])
        pinned.set_dock(["firefox.desktop", "kitty.desktop"])
        reloaded = PinnedApps(self.dir / "pinned-apps.json")
        self.assertEqual(reloaded.get_dock(), ["firefox.desktop", "kitty.desktop"])

    def test_recent_apps_are_capped_and_deduplicated(self):
        pinned = PinnedApps(self.dir / "pinned-apps.json")
        for app in ["a", "b", "c", "a"]:
            pinned.add_recent(app, max_items=2)
        self.assertEqual(pinned.get_recent(), ["a", "c"])


class TestEventBus(unittest.IsolatedAsyncioTestCase):
    async def test_event_emit_subscribe(self):
        bus = EventBus()
        received = []

        async def handler(event_name, data):
            received.append(data)

        await bus.subscribe("test_event", handler)
        await bus.emit("test_event", {"msg": "hello"})
        await asyncio.sleep(0.05)
        self.assertEqual(len(received), 1)
        self.assertEqual(received[0]["msg"], "hello")


class TestSystemMetrics(unittest.TestCase):
    def test_metrics_collection(self):
        metrics = SystemMetrics()
        state = metrics.get_state()
        self.assertIn("cpu_percent", state)
        self.assertIn("ram_percent", state)
        self.assertIn("ram_used_gb", state)
        self.assertIn("ram_total_gb", state)
        self.assertGreaterEqual(state["cpu_percent"], 0)
        self.assertGreaterEqual(state["ram_percent"], 0)


class TestBatteryMonitor(unittest.TestCase):
    def test_battery_read(self):
        bm = BatteryMonitor()
        state = bm.get_state()
        self.assertIn("percent", state)
        self.assertIn("charging", state)
        self.assertIn("status", state)
        self.assertIn("icon", state)


class TestApplications(unittest.IsolatedAsyncioTestCase):
    async def test_app_discovery(self):
        mgr = ApplicationManager()
        apps = await mgr.get_apps()
        self.assertIsInstance(apps, list)
        self.assertGreater(len(apps), 0)
        first = apps[0]
        self.assertIn("name", first)
        self.assertIn("exec", first)


class TestBrightness(unittest.IsolatedAsyncioTestCase):
    async def test_brightness_get(self):
        bm = BrightnessManager()
        val = await bm.get_brightness()
        self.assertIsInstance(val, int)
        self.assertGreaterEqual(val, 0)
        self.assertLessEqual(val, 100)


class TestPowerProfiles(unittest.TestCase):
    def test_parse_profiles_marks_active(self):
        from power.profiles import parse_profiles
        text = (
            "  performance:\n    CpuDriver:\tintel_pstate\n\n"
            "  balanced:\n    CpuDriver:\tintel_pstate\n\n"
            "* power-saver:\n    CpuDriver:\tintel_pstate\n"
        )
        result = parse_profiles(text)
        self.assertEqual(result["active"], "power-saver")
        self.assertEqual(result["profiles"], ["performance", "balanced", "power-saver"])

    def test_parse_profiles_empty(self):
        from power.profiles import parse_profiles
        self.assertEqual(parse_profiles(""), {"active": "", "profiles": []})


if __name__ == "__main__":
    unittest.main()
