"""Battery monitor reading /sys/class/power_supply/BAT0."""
import asyncio
import json
import logging
from pathlib import Path
from typing import Any, Dict, Optional

logger = logging.getLogger(__name__)

STATE_DIR = Path("/tmp/levish")
BATTERY_FILE = STATE_DIR / "battery.json"
BAT_PATH = Path("/sys/class/power_supply/BAT0")
AC_PATH = Path("/sys/class/power_supply/AC")


def _read_sysfs(path: Path) -> Optional[str]:
    try:
        return path.read_text().strip()
    except OSError:
        return None


def _battery_icon(percent: int, charging: bool) -> str:
    if charging:
        suffix = "-charging"
    else:
        suffix = ""

    if percent >= 90:
        base = "battery-full"
    elif percent >= 50:
        base = "battery-good"
    elif percent >= 20:
        base = "battery-low"
    elif percent >= 5:
        base = "battery-caution"
    else:
        base = "battery-empty"

    return base + suffix


class BatteryMonitor:
    """Reads battery state from sysfs and writes /tmp/levish/battery.json."""

    def __init__(self, event_bus=None, interval: float = 30.0) -> None:
        self._bus = event_bus
        self._interval = interval
        self._running = False
        self._task: Optional[asyncio.Task] = None
        self._has_battery: Optional[bool] = None
        try:
            self._state: Dict[str, Any] = self._read_battery()
        except Exception:
            self._state = {}

    async def start(self) -> None:
        self._running = True
        self._has_battery = BAT_PATH.exists()
        if not self._has_battery:
            logger.info("BatteryMonitor: no battery found at %s", BAT_PATH)
        self._task = asyncio.create_task(self._loop())
        logger.info("BatteryMonitor started")

    async def stop(self) -> None:
        self._running = False
        if self._task:
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass
        logger.info("BatteryMonitor stopped")

    def get_state(self) -> Dict[str, Any]:
        return dict(self._state)

    async def _loop(self) -> None:
        while self._running:
            try:
                await self._collect()
            except asyncio.CancelledError:
                raise
            except Exception as exc:
                logger.error("BatteryMonitor poll error: %s", exc)
            await asyncio.sleep(self._interval)

    async def _collect(self) -> None:
        loop = asyncio.get_event_loop()
        state = await loop.run_in_executor(None, self._read_battery)
        self._state = state
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        try:
            BATTERY_FILE.write_text(json.dumps(state, indent=2))
        except OSError as exc:
            logger.error("Failed to write battery.json: %s", exc)
        if self._bus:
            await self._bus.emit("battery_update", state)

    def _read_battery(self) -> Dict[str, Any]:
        if not BAT_PATH.exists():
            # No battery hardware
            return {
                "percent": None,
                "charging": None,
                "status": "Unknown",
                "icon": "battery-missing",
                "has_battery": False,
            }

        percent_str = _read_sysfs(BAT_PATH / "capacity")
        try:
            percent = int(percent_str) if percent_str else 0
        except ValueError:
            percent = 0

        status = _read_sysfs(BAT_PATH / "status") or "Unknown"
        # status values: Charging, Discharging, Full, Not charging, Unknown

        # Check AC adapter
        ac_online_str = _read_sysfs(AC_PATH / "online")
        if ac_online_str is not None:
            ac_online = ac_online_str == "1"
        else:
            ac_online = status in ("Charging", "Full")

        charging = status in ("Charging", "Full") or (ac_online and status != "Discharging")

        # Some systems expose energy_full/energy_now instead of capacity
        if percent_str is None:
            energy_full_str = _read_sysfs(BAT_PATH / "energy_full")
            energy_now_str = _read_sysfs(BAT_PATH / "energy_now")
            try:
                if energy_full_str and energy_now_str:
                    ef = int(energy_full_str)
                    en = int(energy_now_str)
                    percent = int((en / ef) * 100) if ef > 0 else 0
            except (ValueError, ZeroDivisionError):
                percent = 0

        icon = _battery_icon(percent, charging)

        return {
            "percent": percent,
            "charging": charging,
            "status": status,
            "icon": icon,
            "has_battery": True,
        }
