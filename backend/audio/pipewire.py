"""PipeWire/PulseAudio audio control via pactl."""
import asyncio
import json
import logging
import re
from pathlib import Path
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)

STATE_DIR = Path("/tmp/levish")
AUDIO_FILE = STATE_DIR / "audio.json"


def _volume_icon(volume: int, muted: bool) -> str:
    if muted or volume == 0:
        return "audio-volume-muted"
    elif volume <= 33:
        return "audio-volume-low"
    elif volume <= 66:
        return "audio-volume-medium"
    else:
        return "audio-volume-high"


async def _run(cmd: List[str], timeout: float = 5.0) -> str:
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


class AudioManager:
    """Manage audio via pactl (PipeWire/PulseAudio)."""

    def __init__(self, event_bus=None) -> None:
        self._bus = event_bus
        self._running = False
        self._subscribe_task: Optional[asyncio.Task] = None

    async def start(self) -> None:
        self._running = True
        await self._write_state()
        self._subscribe_task = asyncio.create_task(self.subscribe_events())
        logger.info("AudioManager started")

    async def stop(self) -> None:
        self._running = False
        if self._subscribe_task:
            self._subscribe_task.cancel()
            try:
                await self._subscribe_task
            except asyncio.CancelledError:
                pass
        logger.info("AudioManager stopped")

    async def get_volume(self) -> int:
        """Return current default sink volume as int 0-100."""
        out = await _run(["pactl", "get-sink-volume", "@DEFAULT_SINK@"])
        return self._parse_volume(out)

    @staticmethod
    def _parse_volume(text: str) -> int:
        # e.g. "Volume: front-left: 39321 / 60% / -13.06 dB, front-right: ..."
        m = re.search(r"(\d+)%", text)
        if m:
            return int(m.group(1))
        return 0

    async def set_volume(self, percent: int) -> None:
        """Set default sink volume (0-100)."""
        percent = max(0, min(100, percent))
        await _run(["pactl", "set-sink-volume", "@DEFAULT_SINK@", f"{percent}%"])
        await self._write_state()

    async def toggle_mute(self) -> None:
        """Toggle mute on default sink."""
        await _run(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"])
        await self._write_state()

    async def get_muted(self) -> bool:
        """Return True if default sink is muted."""
        out = await _run(["pactl", "get-sink-mute", "@DEFAULT_SINK@"])
        return "yes" in out.lower()

    async def get_sinks(self) -> List[Dict[str, Any]]:
        """Return list of sink dicts."""
        out = await _run(["pactl", "-f", "json", "list", "sinks"])
        if not out:
            return []
        try:
            raw = json.loads(out)
            default_sink = await _run(["pactl", "get-default-sink"])
            default_sink = default_sink.strip()
            sinks = []
            for s in raw:
                name = s.get("name", "")
                vol_data = s.get("volume", {})
                # Average all channel volumes
                channels = list(vol_data.values()) if vol_data else []
                vol_pct = 0
                if channels:
                    total = sum(c.get("value_percent", "0%").rstrip("%") and int(c.get("value_percent", "0%").rstrip("%")) for c in channels)
                    vol_pct = total // len(channels)
                sinks.append({
                    "name": name,
                    "description": s.get("description", ""),
                    "volume": vol_pct,
                    "muted": s.get("mute", False),
                    "default": name == default_sink,
                })
            return sinks
        except (json.JSONDecodeError, Exception) as exc:
            logger.debug("get_sinks parse error: %s", exc)
            return []

    async def set_default_sink(self, name: str) -> None:
        """Set the default sink by name."""
        await _run(["pactl", "set-default-sink", name])
        await self._write_state()

    async def get_sources(self) -> List[Dict[str, Any]]:
        """Return list of source (microphone) dicts."""
        out = await _run(["pactl", "-f", "json", "list", "sources"])
        if not out:
            return []
        try:
            raw = json.loads(out)
            default_source = await _run(["pactl", "get-default-source"])
            default_source = default_source.strip()
            sources = []
            for s in raw:
                name = s.get("name", "")
                # Skip monitor sources
                if ".monitor" in name:
                    continue
                sources.append({
                    "name": name,
                    "description": s.get("description", ""),
                    "muted": s.get("mute", False),
                    "default": name == default_source,
                })
            return sources
        except Exception as exc:
            logger.debug("get_sources parse error: %s", exc)
            return []

    async def _get_source_muted(self) -> bool:
        out = await _run(["pactl", "get-source-mute", "@DEFAULT_SOURCE@"])
        return "yes" in out.lower()

    async def _write_state(self) -> None:
        volume = await self.get_volume()
        muted = await self.get_muted()
        source_muted = await self._get_source_muted()
        state = {
            "volume": volume,
            "muted": muted,
            "icon": _volume_icon(volume, muted),
            "source_muted": source_muted,
        }
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        try:
            AUDIO_FILE.write_text(json.dumps(state, indent=2))
        except OSError as exc:
            logger.error("Failed to write audio.json: %s", exc)
        if self._bus:
            await self._bus.emit("audio_update", state)

    async def subscribe_events(self) -> None:
        """Watch pactl subscribe for sink/source changes and update state."""
        while self._running:
            try:
                proc = await asyncio.create_subprocess_exec(
                    "pactl", "subscribe",
                    stdout=asyncio.subprocess.PIPE,
                    stderr=asyncio.subprocess.DEVNULL,
                )
                while self._running:
                    line_bytes = await proc.stdout.readline()  # type: ignore[union-attr]
                    if not line_bytes:
                        break
                    line = line_bytes.decode(errors="replace").strip()
                    if any(kw in line for kw in ("sink", "source", "server")):
                        try:
                            await self._write_state()
                        except Exception as exc:
                            logger.debug("audio state update error: %s", exc)
                try:
                    proc.kill()
                except Exception:
                    pass
            except asyncio.CancelledError:
                raise
            except Exception as exc:
                logger.error("AudioManager subscribe error: %s", exc)
            await asyncio.sleep(2)
