#!/usr/bin/env python3
"""
Unit tests for Levish backend components.
"""
import sys
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
    def test_config_defaults(self):
        cfg = Config()
        self.assertEqual(cfg.get("theme.bg_primary"), "#1a1a2e")
        self.assertEqual(cfg.get("bar.height"), 42)
        self.assertEqual(cfg.get("metrics_interval"), 2)

    def test_config_set_get(self):
        cfg = Config()
        cfg.set("theme.font_size", 14)
        self.assertEqual(cfg.get("theme.font_size"), 14)

    def test_pinned_apps(self):
        pinned = PinnedApps()
        dock = pinned.get_dock()
        self.assertIsInstance(dock, list)
        self.assertTrue(len(dock) > 0)


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
