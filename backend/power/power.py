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


def _levish_hyprlock_conf():
    """Path of the hyprlock config Levish writes, or None if it has not been written yet.

    Must match quickshell/lock/LockService.qml, which writes to $XDG_STATE_HOME/levish.
    """
    import os
    from pathlib import Path
    base = os.environ.get("XDG_STATE_HOME") or str(Path.home() / ".local" / "state")
    conf = Path(base) / "levish" / "hyprlock.conf"
    if conf.is_file():
        return conf
    tmp_conf = Path("/tmp/levish/hyprlock.conf")
    return tmp_conf if tmp_conf.is_file() else None


class PowerManager:
    """System power operations."""

    # The running hyprlock process, so a second lock request does not start another one.
    _lock_proc = None

    async def lock(self) -> Tuple[bool, str]:
        """Lock the session.

        Preferred: Levish shell IPC (native ext-session-lock-v1 lock screen).
        Fallbacks: hyprlock with Levish config, loginctl, hyprlock default, swaylock.
        """
        logger.info("PowerManager: locking session")
        # Try Levish IPC first
        project_root = Path(__file__).resolve().parent.parent.parent
        ipc_script = project_root / "scripts" / "levish-ipc.sh"
        if ipc_script.is_file():
            ok, msg = await _run_cmd(str(ipc_script), "lock")
            if ok:
                return True, "Session locked via Levish IPC"
            logger.debug("Levish IPC lock returned: %s, falling back to hyprlock", msg)

        conf = _levish_hyprlock_conf()
        if conf is not None:
            if self._lock_proc is not None and self._lock_proc.returncode is None:
                return True, "Already locked"
            try:
                self._lock_proc = await asyncio.create_subprocess_exec(
                    "hyprlock", "-c", str(conf),
                    stdin=asyncio.subprocess.DEVNULL,
                    stdout=asyncio.subprocess.DEVNULL,
                    stderr=asyncio.subprocess.DEVNULL,
                    start_new_session=True,
                )
                return True, "Session locked via hyprlock (Levish config)"
            except FileNotFoundError:
                logger.debug("hyprlock not installed, using fallbacks")
            except Exception as exc:
                logger.debug("hyprlock with Levish config failed: %s", exc)
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
        # Hyprland 0.57 reads dispatchers as Lua; the legacy "exit" form is rejected.
        ok, msg = await _run_cmd("hyprctl", "dispatch", "hl.dsp.exit()")
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
