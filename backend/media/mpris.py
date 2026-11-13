"""MPRIS media player control via playerctl."""
import asyncio
import json
import logging
from pathlib import Path
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)

STATE_DIR = Path("/tmp/levish")
MEDIA_FILE = STATE_DIR / "media.json"


async def _run(cmd: List[str], timeout: float = 4.0) -> str:
    try:
        proc = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        stdout, _ = await asyncio.wait_for(proc.communicate(), timeout=timeout)
        return stdout.decode(errors="replace").strip()
    except (asyncio.TimeoutError, FileNotFoundError, OSError):
        return ""


class MediaPlayer:
    """MPRIS2 media control via playerctl subprocess."""

    def __init__(self, event_bus=None, interval: float = 2.0) -> None:
        self._bus = event_bus
        self._interval = interval
        self._running = False
        self._task: Optional[asyncio.Task] = None
        self._state: Dict[str, Any] = {
            "playing": False,
            "title": "",
            "artist": "",
            "album": "",
            "art_url": "",
            "player": "",
        }

    async def start(self) -> None:
        self._running = True
        await self._collect()
        self._task = asyncio.create_task(self._loop())
        logger.info("MediaPlayer started")

    async def stop(self) -> None:
        self._running = False
        if self._task:
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass
        logger.info("MediaPlayer stopped")

    def get_state(self) -> Dict[str, Any]:
        return dict(self._state)

    async def _loop(self) -> None:
        while self._running:
            try:
                await self._collect()
            except asyncio.CancelledError:
                raise
            except Exception as exc:
                logger.error("MediaPlayer poll error: %s", exc)
            await asyncio.sleep(self._interval)

    async def list_players(self) -> List[str]:
        """Return list of active player names."""
        out = await _run(["playerctl", "-l"])
        if not out:
            return []
        return [p.strip() for p in out.splitlines() if p.strip()]

    async def get_state(self) -> Dict[str, Any]:  # type: ignore[override]
        """Return current playback state dict."""
        await self._collect()
        return dict(self._state)

    async def _collect(self) -> None:
        players = await self.list_players()
        if not players:
            state: Dict[str, Any] = {
                "playing": False,
                "title": "",
                "artist": "",
                "album": "",
                "art_url": "",
                "player": "",
            }
            self._state = state
            await self._write(state)
            return

        player = players[0]

        status_out = await _run(["playerctl", "--player", player, "status"])
        playing = status_out.strip().lower() == "playing"

        title = await _run(["playerctl", "--player", player, "metadata", "title"])
        artist = await _run(["playerctl", "--player", player, "metadata", "artist"])
        album = await _run(["playerctl", "--player", player, "metadata", "album"])
        art_url = await _run(["playerctl", "--player", player, "metadata", "mpris:artUrl"])

        state = {
            "playing": playing,
            "title": title,
            "artist": artist,
            "album": album,
            "art_url": art_url,
            "player": player,
        }
        self._state = state
        await self._write(state)

    async def _write(self, state: Dict[str, Any]) -> None:
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        try:
            MEDIA_FILE.write_text(json.dumps(state, indent=2))
        except OSError as exc:
            logger.error("Failed to write media.json: %s", exc)
        if self._bus:
            await self._bus.emit("media_update", state)

    async def play_pause(self) -> None:
        """Toggle play/pause on the active player."""
        await _run(["playerctl", "play-pause"])
        await asyncio.sleep(0.1)
        await self._collect()

    async def next(self) -> None:
        """Skip to next track."""
        await _run(["playerctl", "next"])
        await asyncio.sleep(0.1)
        await self._collect()

    async def previous(self) -> None:
        """Go to previous track."""
        await _run(["playerctl", "previous"])
        await asyncio.sleep(0.1)
        await self._collect()

    async def set_volume(self, level: float) -> None:
        """Set player volume (0.0 - 1.0)."""
        level = max(0.0, min(1.0, level))
        await _run(["playerctl", "volume", str(level)])

    async def seek(self, offset_seconds: float) -> None:
        """Seek forward/backward by offset_seconds."""
        await _run(["playerctl", "position", f"{offset_seconds:+.0f}+"])
