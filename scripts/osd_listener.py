#!/usr/bin/env python3
"""
OSD listener daemon for Levish.
Monitors volume (pactl subscribe) and brightness (sysfs polling)
and writes /tmp/levish/osd.json when values change.
"""
import asyncio
import json
import os
import re
import signal
import sys
import time
from pathlib import Path

OSD_FILE        = Path("/tmp/levish/osd.json")
BRIGHTNESS_FILE = Path("/sys/class/backlight/intel_backlight/brightness")
BRIGHTNESS_MAX  = Path("/sys/class/backlight/intel_backlight/max_brightness")
HIDE_AFTER      = 2.5   # seconds

_hide_task: asyncio.Task | None = None
_loop: asyncio.AbstractEventLoop | None = None


def write_osd(visible: bool, osd_type: str, value: int):
    OSD_FILE.parent.mkdir(parents=True, exist_ok=True)
    OSD_FILE.write_text(json.dumps({
        "visible": visible,
        "type": osd_type,
        "value": value
    }))


async def hide_after_delay():
    """Hide OSD after HIDE_AFTER seconds of inactivity."""
    await asyncio.sleep(HIDE_AFTER)
    write_osd(False, "volume", 0)


def schedule_hide():
    global _hide_task
    if _hide_task and not _hide_task.done():
        _hide_task.cancel()
    _hide_task = asyncio.ensure_future(hide_after_delay())


async def get_volume() -> tuple[int, bool]:
    """Return (volume_percent, muted)."""
    try:
        proc = await asyncio.create_subprocess_exec(
            "pactl", "get-sink-volume", "@DEFAULT_SINK@",
            stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.DEVNULL
        )
        out, _ = await asyncio.wait_for(proc.communicate(), timeout=3)
        text = out.decode()
        m = re.search(r'(\d+)%', text)
        vol = int(m.group(1)) if m else 50

        proc2 = await asyncio.create_subprocess_exec(
            "pactl", "get-sink-mute", "@DEFAULT_SINK@",
            stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.DEVNULL
        )
        out2, _ = await asyncio.wait_for(proc2.communicate(), timeout=3)
        muted = "yes" in out2.decode().lower()
        return (0 if muted else vol), muted
    except Exception:
        return 50, False


async def watch_volume():
    """Subscribe to pactl events and update OSD on volume/mute changes."""
    while True:
        try:
            proc = await asyncio.create_subprocess_exec(
                "pactl", "subscribe",
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.DEVNULL
            )
            async for line in proc.stdout:
                text = line.decode().strip()
                if "sink" in text and ("change" in text or "new" in text):
                    await asyncio.sleep(0.05)
                    vol, muted = await get_volume()
                    write_osd(True, "volume", vol)
                    schedule_hide()
        except asyncio.CancelledError:
            return
        except Exception:
            await asyncio.sleep(2)


def read_brightness() -> int:
    """Return brightness as 0-100 percent."""
    try:
        cur = int(BRIGHTNESS_FILE.read_text().strip())
        mx  = int(BRIGHTNESS_MAX.read_text().strip())
        if mx == 0:
            return 70
        return max(0, min(100, round(cur * 100 / mx)))
    except Exception:
        return 70


async def watch_brightness():
    """Poll brightness every 0.5s and update OSD on change."""
    prev = -1
    while True:
        try:
            current = read_brightness()
            if current != prev:
                if prev != -1:
                    write_osd(True, "brightness", current)
                    schedule_hide()
                prev = current
        except asyncio.CancelledError:
            return
        except Exception:
            pass
        await asyncio.sleep(0.5)


async def main():
    global _loop
    _loop = asyncio.get_running_loop()

    OSD_FILE.parent.mkdir(parents=True, exist_ok=True)
    write_osd(False, "volume", 50)

    def _shutdown(*_):
        sys.exit(0)

    signal.signal(signal.SIGTERM, _shutdown)
    signal.signal(signal.SIGINT, _shutdown)

    await asyncio.gather(
        watch_volume(),
        watch_brightness(),
    )


if __name__ == "__main__":
    asyncio.run(main())
