"""Hyprland IPC client over Unix sockets."""
import asyncio
import json
import logging
import os
from pathlib import Path
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)

STATE_DIR = Path("/tmp/levish")
WORKSPACES_FILE = STATE_DIR / "workspaces.json"
ACTIVE_WINDOW_FILE = STATE_DIR / "active_window.json"


def _get_socket_paths() -> Optional[tuple]:
    """Locate Hyprland's IPC sockets.

    Hyprland >= 0.40 keeps them under $XDG_RUNTIME_DIR/hypr/<sig>/; older
    releases used /tmp/hypr/<sig>/, so that is kept as a fallback.
    """
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if not sig:
        return None
    runtime = os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}"
    for base in (Path(runtime) / "hypr", Path("/tmp/hypr")):
        cmd_sock = base / sig / ".socket.sock"
        evt_sock = base / sig / ".socket2.sock"
        if cmd_sock.exists() and evt_sock.exists():
            return str(cmd_sock), str(evt_sock)
    return None


class HyprlandIPC:
    """Communicates with Hyprland via Unix socket IPC."""

    def __init__(self, event_bus=None) -> None:
        self._bus = event_bus
        self._running = False
        self._listen_task: Optional[asyncio.Task] = None
        paths = _get_socket_paths()
        if paths:
            self._cmd_sock, self._evt_sock = paths
            self._dev_mode = False
        else:
            self._cmd_sock = ""
            self._evt_sock = ""
            self._dev_mode = True
            logger.warning(
                "HyprlandIPC: HYPRLAND_INSTANCE_SIGNATURE not set — running in dev mode"
            )

    async def start(self) -> None:
        self._running = True
        if not self._dev_mode:
            # Initial state
            try:
                await self._write_workspaces()
            except Exception as exc:
                logger.error("HyprlandIPC initial workspace fetch failed: %s", exc)
            self._listen_task = asyncio.create_task(self.listen_events())
        logger.info("HyprlandIPC started (dev_mode=%s)", self._dev_mode)

    async def stop(self) -> None:
        self._running = False
        if self._listen_task:
            self._listen_task.cancel()
            try:
                await self._listen_task
            except asyncio.CancelledError:
                pass
        logger.info("HyprlandIPC stopped")

    async def send_command(self, cmd: str) -> str:
        """Send a command to the Hyprland command socket and return the response."""
        if self._dev_mode:
            return ""
        try:
            reader, writer = await asyncio.open_unix_connection(self._cmd_sock)
            writer.write(cmd.encode())
            await writer.drain()
            data = await reader.read(65536)
            writer.close()
            await writer.wait_closed()
            return data.decode(errors="replace").strip()
        except Exception as exc:
            logger.error("HyprlandIPC send_command '%s' failed: %s", cmd, exc)
            return ""

    async def get_workspaces(self) -> List[Dict[str, Any]]:
        """Return list of workspace dicts from j/workspaces."""
        raw = await self.send_command("j/workspaces")
        if not raw:
            return []
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            return []

    async def get_active_workspace(self) -> Dict[str, Any]:
        """Return active workspace dict from j/activeworkspace."""
        raw = await self.send_command("j/activeworkspace")
        if not raw:
            return {}
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            return {}

    async def get_active_window(self) -> Dict[str, Any]:
        """Return active window dict from j/activewindow."""
        raw = await self.send_command("j/activewindow")
        if not raw:
            return {}
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            return {}

    async def switch_workspace(self, n: int) -> None:
        """Switch to workspace n."""
        await self.send_command(f"dispatch hl.dsp.focus({{ workspace = {n} }})")

    async def _write_workspaces(self) -> None:
        """Fetch workspace state and write to workspaces.json."""
        workspaces = await self.get_workspaces()
        active = await self.get_active_workspace()
        active_id = active.get("id", -1)

        # Build a compact list of workspaces 1-10 (Hyprland standard)
        ws_map: Dict[int, bool] = {}
        for ws in workspaces:
            ws_id = ws.get("id", 0)
            ws_map[ws_id] = True

        result = []
        max_id = max(ws_map.keys()) if ws_map else 10
        max_id = max(max_id, 10)
        for i in range(1, max_id + 1):
            result.append(
                {
                    "id": i,
                    "active": i == active_id,
                    "occupied": i in ws_map,
                }
            )

        STATE_DIR.mkdir(parents=True, exist_ok=True)
        WORKSPACES_FILE.write_text(json.dumps(result, indent=2))

        active_win = await self.get_active_window()
        win_data = {
            "title": active_win.get("title", ""),
            "class": active_win.get("class", ""),
            "address": active_win.get("address", ""),
        }
        ACTIVE_WINDOW_FILE.write_text(json.dumps(win_data, indent=2))

    async def listen_events(self) -> None:
        """Listen on the event socket and emit bus events."""
        if self._dev_mode:
            return
        while self._running:
            try:
                reader, writer = await asyncio.open_unix_connection(self._evt_sock)
                logger.info("HyprlandIPC: connected to event socket")
                while self._running:
                    line = await reader.readline()
                    if not line:
                        break
                    decoded = line.decode(errors="replace").strip()
                    await self._handle_event(decoded)
                writer.close()
                try:
                    await writer.wait_closed()
                except Exception:
                    pass
            except asyncio.CancelledError:
                raise
            except Exception as exc:
                logger.error("HyprlandIPC event socket error: %s", exc)
                await asyncio.sleep(2)

    async def _handle_event(self, line: str) -> None:
        """Parse and dispatch a Hyprland event line."""
        if ">>" not in line:
            return
        event_type, _, payload = line.partition(">>")
        event_type = event_type.strip()
        payload = payload.strip()

        if event_type == "workspace":
            try:
                ws_id = int(payload)
            except ValueError:
                ws_id = payload
            if self._bus:
                await self._bus.emit("hypr_workspace", {"id": ws_id})
            await self._write_workspaces()

        elif event_type == "activewindow":
            parts = payload.split(",", 1)
            win_class = parts[0] if len(parts) > 0 else ""
            win_title = parts[1] if len(parts) > 1 else ""
            win_data = {"class": win_class, "title": win_title}
            STATE_DIR.mkdir(parents=True, exist_ok=True)
            ACTIVE_WINDOW_FILE.write_text(json.dumps({**win_data, "address": ""}, indent=2))
            if self._bus:
                await self._bus.emit("hypr_active_window", win_data)

        elif event_type == "activewindowv2":
            STATE_DIR.mkdir(parents=True, exist_ok=True)
            if self._bus:
                await self._bus.emit("hypr_active_window_v2", {"address": payload})

        elif event_type == "openwindow":
            parts = payload.split(",", 3)
            data = {
                "address": parts[0] if len(parts) > 0 else "",
                "workspace": parts[1] if len(parts) > 1 else "",
                "class": parts[2] if len(parts) > 2 else "",
                "title": parts[3] if len(parts) > 3 else "",
            }
            if self._bus:
                await self._bus.emit("hypr_open_window", data)

        elif event_type == "closewindow":
            if self._bus:
                await self._bus.emit("hypr_close_window", {"address": payload})

        elif event_type == "createworkspace":
            try:
                ws_id = int(payload)
            except ValueError:
                ws_id = payload
            if self._bus:
                await self._bus.emit("hypr_create_workspace", {"id": ws_id})
            await self._write_workspaces()

        elif event_type == "destroyworkspace":
            try:
                ws_id = int(payload)
            except ValueError:
                ws_id = payload
            if self._bus:
                await self._bus.emit("hypr_destroy_workspace", {"id": ws_id})
            await self._write_workspaces()

        elif event_type == "fullscreen":
            if self._bus:
                await self._bus.emit("hypr_fullscreen", {"active": payload == "1"})

        elif event_type == "monitorremoved":
            if self._bus:
                await self._bus.emit("hypr_monitor_removed", {"name": payload})

        elif event_type == "monitoradded":
            if self._bus:
                await self._bus.emit("hypr_monitor_added", {"name": payload})

        else:
            logger.debug("HyprlandIPC unhandled event: %s >> %s", event_type, payload)
