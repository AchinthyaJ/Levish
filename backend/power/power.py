"""Power management actions: lock, suspend, restart, shutdown, logout."""
import asyncio
import logging
from typing import Tuple

logger = logging.getLogger(__name__)


async def _run_cmd(*args: str) -> Tuple[bool, str]:
    """Run a command and return (success, output/error)."""
    try:
        proc = await asyncio.create_subprocess_exec(
            *args,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        stdout, stderr = await asyncio.wait_for(proc.communicate(), timeout=10.0)
        success = proc.returncode == 0
        output = (stdout or stderr).decode(errors="replace").strip()
        return success, output
    except asyncio.TimeoutError:
        return False, "Command timed out"
    except FileNotFoundError:
        return False, f"Command not found: {args[0]}"
    except Exception as exc:
        return False, str(exc)


class PowerManager:
    """System power operations."""

    async def lock(self) -> Tuple[bool, str]:
        """Lock the screen. Tries loginctl, then hyprlock, then swaylock."""
        logger.info("PowerManager: locking session")
        ok, msg = await _run_cmd("loginctl", "lock-session")
        if ok:
            return True, "Session locked via loginctl"
        logger.debug("loginctl failed (%s), trying hyprlock", msg)
        ok, msg = await _run_cmd("hyprlock")
        if ok:
            return True, "Session locked via hyprlock"
        logger.debug("hyprlock failed (%s), trying swaylock", msg)
        ok, msg = await _run_cmd("swaylock")
        if ok:
            return True, "Session locked via swaylock"
        return False, f"All lock commands failed: {msg}"

    async def suspend(self) -> Tuple[bool, str]:
        """Suspend the system."""
        logger.info("PowerManager: suspending")
        ok, msg = await _run_cmd("systemctl", "suspend")
        if ok:
            return True, "System suspended"
        return False, f"Suspend failed: {msg}"

    async def restart(self) -> Tuple[bool, str]:
        """Reboot the system."""
        logger.info("PowerManager: rebooting")
        ok, msg = await _run_cmd("systemctl", "reboot")
        if ok:
            return True, "System rebooting"
        return False, f"Reboot failed: {msg}"

    async def shutdown(self) -> Tuple[bool, str]:
        """Power off the system."""
        logger.info("PowerManager: shutting down")
        ok, msg = await _run_cmd("systemctl", "poweroff")
        if ok:
            return True, "System shutting down"
        return False, f"Shutdown failed: {msg}"

    async def logout(self) -> Tuple[bool, str]:
        """Log out of the Hyprland session."""
        logger.info("PowerManager: logging out")
        ok, msg = await _run_cmd("hyprctl", "dispatch", "exit")
        if ok:
            return True, "Logged out"
        return False, f"Logout failed: {msg}"

    async def hibernate(self) -> Tuple[bool, str]:
        """Hibernate the system."""
        logger.info("PowerManager: hibernating")
        ok, msg = await _run_cmd("systemctl", "hibernate")
        if ok:
            return True, "System hibernating"
        return False, f"Hibernate failed: {msg}"
