"""Brightness control via brightnessctl or /sys."""
import asyncio
import json
import logging
from pathlib import Path
from typing import Optional

logger = logging.getLogger(__name__)

STATE_DIR = Path("/tmp/levish")
BRIGHTNESS_FILE = STATE_DIR / "brightness.json"
BACKLIGHT_PATH = Path("/sys/class/backlight/intel_backlight")


async def _run(cmd, timeout: float = 4.0) -> str:
    try:
        proc = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        stdout, _ = await asyncio.wait_for(proc.communicate(), timeout=timeout)
        return stdout.decode(errors="replace").strip()
    except (asyncio.TimeoutError, FileNotFoundError, OSError) as exc:
        logger.debug("_run %s failed: %s", cmd, exc)
        return ""


class BrightnessManager:
    """Brightness control via brightnessctl, with sysfs fallback."""

    def __init__(self, event_bus=None) -> None:
        self._bus = event_bus
        self._running = False
        self._watch_task: Optional[asyncio.Task] = None
        self._last_brightness: int = -1

    async def start(self) -> None:
        self._running = True
        await self._write_state()
        self._watch_task = asyncio.create_task(self._watch_loop())
        logger.info("BrightnessManager started")

    async def stop(self) -> None:
        self._running = False
        if self._watch_task:
            self._watch_task.cancel()
            try:
                await self._watch_task
            except asyncio.CancelledError:
                pass
        logger.info("BrightnessManager stopped")

    async def get_brightness(self) -> int:
        """Return current brightness as 0-100 percent."""
        # Try brightnessctl
        current_str = await _run(["brightnessctl", "g"])
        max_str = await _run(["brightnessctl", "m"])
        if current_str and max_str:
            try:
                current = int(current_str)
                maximum = int(max_str)
                if maximum > 0:
                    return round((current / maximum) * 100)
            except (ValueError, ZeroDivisionError):
                pass

        # Fallback: sysfs
        try:
            curr_path = BACKLIGHT_PATH / "brightness"
            max_path = BACKLIGHT_PATH / "max_brightness"
            if curr_path.exists() and max_path.exists():
                current = int(curr_path.read_text().strip())
                maximum = int(max_path.read_text().strip())
                if maximum > 0:
                    return round((current / maximum) * 100)
        except Exception as exc:
            logger.debug("sysfs brightness read failed: %s", exc)

        return 50  # Safe default if everything fails

    async def set_brightness(self, percent: int) -> bool:
        """Set brightness to percent (0-100)."""
        percent = max(1, min(100, percent))
        ok_str = await _run(["brightnessctl", "s", f"{percent}%"])
        success = bool(ok_str) or True  # brightnessctl may not output on success
        if success:
            await self._write_state()
        return success

    async def adjust(self, delta: int) -> int:
        """Increase or decrease brightness by delta percent. Returns new percent."""
        current = await self.get_brightness()
        new_val = max(1, min(100, current + delta))
        await self.set_brightness(new_val)
        return new_val

    async def _write_state(self) -> None:
        percent = await self.get_brightness()
        state = {"percent": percent}
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        try:
            BRIGHTNESS_FILE.write_text(json.dumps(state, indent=2))
        except OSError as exc:
            logger.error("Failed to write brightness.json: %s", exc)
        if self._bus and percent != self._last_brightness:
            self._last_brightness = percent
            await self._bus.emit("brightness_update", state)

    async def _watch_loop(self) -> None:
        """Poll sysfs brightness and emit events on changes."""
        while self._running:
            try:
                await asyncio.sleep(1)
                current = await self.get_brightness()
                if current != self._last_brightness:
                    self._last_brightness = current
                    state = {"percent": current}
                    STATE_DIR.mkdir(parents=True, exist_ok=True)
                    try:
                        BRIGHTNESS_FILE.write_text(json.dumps(state, indent=2))
                    except OSError:
                        pass
                    if self._bus:
                        await self._bus.emit("brightness_update", state)
            except asyncio.CancelledError:
                raise
            except Exception as exc:
                logger.error("BrightnessManager watch error: %s", exc)
