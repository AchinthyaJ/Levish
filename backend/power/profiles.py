"""Power profiles (power-saver / balanced / performance) via powerprofilesctl.

Writes /tmp/levish/power_profiles.json so the control centre can show and switch the
active profile. Only the names reported by powerprofilesctl are accepted for switching.
"""
import asyncio
import json
import logging
import re
from pathlib import Path
from typing import Any, Dict, List

logger = logging.getLogger(__name__)

STATE_DIR = Path("/tmp/levish")
PROFILE_FILE = STATE_DIR / "power_profiles.json"
POLL_SECONDS = 20.0

_HEADER_RE = re.compile(r"^(\*?)\s*([a-z][a-z-]*):\s*$")


def parse_profiles(text: str) -> Dict[str, Any]:
    """Parse `powerprofilesctl list` output into {"active": str, "profiles": [str]}."""
    profiles: List[str] = []
    active = ""
    for line in text.splitlines():
        m = _HEADER_RE.match(line.rstrip())
        if not m:
            continue
        name = m.group(2)
        profiles.append(name)
        if m.group(1) == "*":
            active = name
    return {"active": active, "profiles": profiles}


async def _run(*args: str, timeout: float = 5.0) -> str:
    try:
        proc = await asyncio.create_subprocess_exec(
            *args, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
        )
        out, _ = await asyncio.wait_for(proc.communicate(), timeout=timeout)
        return out.decode(errors="replace")
    except (asyncio.TimeoutError, FileNotFoundError, OSError) as exc:
        logger.debug("power profiles: %s failed: %s", args, exc)
        return ""


class PowerProfileManager:
    """Keeps power_profiles.json current and switches profiles on request."""

    def __init__(self, event_bus=None) -> None:
        self._bus = event_bus
        self._running = False
        self._task = None
        self._state: Dict[str, Any] = {"active": "", "profiles": []}

    async def start(self) -> None:
        self._running = True
        await self.refresh()
        self._task = asyncio.create_task(self._loop())

    async def stop(self) -> None:
        self._running = False
        if self._task:
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass

    async def _loop(self) -> None:
        while self._running:
            await asyncio.sleep(POLL_SECONDS)
            try:
                await self.refresh()
            except Exception as exc:
                logger.error("PowerProfileManager poll error: %s", exc)

    async def refresh(self) -> Dict[str, Any]:
        state = parse_profiles(await _run("powerprofilesctl", "list"))
        self._state = state
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        try:
            PROFILE_FILE.write_text(json.dumps(state, indent=2))
        except OSError as exc:
            logger.error("Failed to write power_profiles.json: %s", exc)
        return state

    async def set_profile(self, name: str) -> bool:
        if name not in self._state.get("profiles", []):
            await self.refresh()
        if name not in self._state.get("profiles", []):
            return False
        await _run("powerprofilesctl", "set", name)
        await self.refresh()
        return self._state.get("active") == name
