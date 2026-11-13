"""NetworkManager control via nmcli."""
import asyncio
import json
import logging
from pathlib import Path
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)

STATE_DIR = Path("/tmp/levish")
NETWORK_FILE = STATE_DIR / "network.json"


def _wifi_icon(signal: int, conn_type: str, connected: bool) -> str:
    if not connected:
        return "network-offline"
    if conn_type == "ethernet":
        return "network-wired"
    if signal <= 25:
        return "network-wireless-signal-poor"
    elif signal <= 50:
        return "network-wireless-signal-ok"
    elif signal <= 75:
        return "network-wireless-signal-good"
    else:
        return "network-wireless-signal-excellent"


async def _run(cmd: List[str], timeout: float = 8.0) -> str:
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


class NetworkManager:
    """NetworkManager interface via nmcli."""

    def __init__(self, event_bus=None, interval: float = 10.0) -> None:
        self._bus = event_bus
        self._interval = interval
        self._running = False
        self._task: Optional[asyncio.Task] = None
        self._state: Dict[str, Any] = {}

    async def start(self) -> None:
        self._running = True
        await self._collect()
        self._task = asyncio.create_task(self._loop())
        logger.info("NetworkManager started")

    async def stop(self) -> None:
        self._running = False
        if self._task:
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass
        logger.info("NetworkManager stopped")

    def get_state(self) -> Dict[str, Any]:
        return dict(self._state)

    async def _loop(self) -> None:
        while self._running:
            try:
                await self._collect()
            except asyncio.CancelledError:
                raise
            except Exception as exc:
                logger.error("NetworkManager poll error: %s", exc)
            await asyncio.sleep(self._interval)

    async def get_status(self) -> Dict[str, Any]:
        """Return current network status dict."""
        # General state
        general_out = await _run(["nmcli", "-t", "-f", "STATE,CONNECTIVITY", "general"])
        nm_state = ""
        nm_connectivity = ""
        for line in general_out.splitlines():
            parts = line.split(":", 1)
            if len(parts) == 2:
                nm_state = parts[0].strip()
                nm_connectivity = parts[1].strip()
                break

        connected = nm_state.lower() in ("connected", "connecting")

        # Active connection
        active_out = await _run([
            "nmcli", "-t", "-f", "NAME,TYPE,DEVICE,STATE",
            "connection", "show", "--active"
        ])
        conn_name = ""
        conn_type = "unknown"
        conn_device = ""
        for line in active_out.splitlines():
            parts = line.split(":", 3)
            if len(parts) >= 3:
                conn_name = parts[0]
                conn_type_raw = parts[1]
                conn_device = parts[2]
                if "wifi" in conn_type_raw or "wireless" in conn_type_raw:
                    conn_type = "wifi"
                elif "ethernet" in conn_type_raw or "802-3" in conn_type_raw:
                    conn_type = "ethernet"
                break

        # WiFi details
        ssid = ""
        signal = 0
        if conn_type == "wifi":
            wifi_out = await _run([
                "nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,BARS",
                "device", "wifi", "list"
            ])
            for line in wifi_out.splitlines():
                parts = line.split(":", 3)
                if len(parts) >= 3 and parts[0].strip() == "*":
                    ssid = parts[1].strip()
                    try:
                        signal = int(parts[2].strip())
                    except ValueError:
                        signal = 0
                    break

        # IP address
        ip = ""
        if conn_device:
            ip_out = await _run([
                "nmcli", "-t", "-f", "IP4.ADDRESS", "device", "show", conn_device
            ])
            for line in ip_out.splitlines():
                if "IP4.ADDRESS" in line:
                    addr = line.split(":", 1)[-1].strip()
                    ip = addr.split("/")[0]  # strip prefix length
                    break

        icon = _wifi_icon(signal, conn_type, connected)

        return {
            "connected": connected,
            "ssid": ssid or conn_name,
            "signal": signal,
            "icon": icon,
            "type": conn_type,
            "ip": ip,
        }

    async def _collect(self) -> None:
        state = await self.get_status()
        self._state = state
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        try:
            NETWORK_FILE.write_text(json.dumps(state, indent=2))
        except OSError as exc:
            logger.error("Failed to write network.json: %s", exc)
        if self._bus:
            await self._bus.emit("network_update", state)

    async def list_wifi_networks(self) -> List[Dict[str, Any]]:
        """Return list of visible wifi networks."""
        # Rescan first
        await _run(["nmcli", "device", "wifi", "rescan"])
        out = await _run([
            "nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY",
            "device", "wifi", "list"
        ])
        networks = []
        for line in out.splitlines():
            parts = line.split(":", 3)
            if len(parts) < 3:
                continue
            in_use = parts[0].strip() == "*"
            ssid = parts[1].strip()
            if not ssid:
                continue
            try:
                sig = int(parts[2].strip())
            except ValueError:
                sig = 0
            secured = len(parts) > 3 and bool(parts[3].strip())
            networks.append({
                "ssid": ssid,
                "signal": sig,
                "secured": secured,
                "in_use": in_use,
            })
        return networks

    async def connect_wifi(self, ssid: str, password: Optional[str] = None) -> bool:
        """Connect to a WiFi network."""
        cmd = ["nmcli", "device", "wifi", "connect", ssid]
        if password:
            cmd += ["password", password]
        out = await _run(cmd, timeout=30.0)
        success = "successfully" in out.lower() or "activated" in out.lower()
        if success:
            await self._collect()
        return success

    async def disconnect(self) -> None:
        """Disconnect active wifi."""
        await _run(["nmcli", "device", "disconnect", "wlan0"])
        await self._collect()

    async def toggle_wifi(self) -> None:
        """Toggle WiFi radio."""
        status_out = await _run(["nmcli", "radio", "wifi"])
        if "enabled" in status_out.lower():
            await _run(["nmcli", "radio", "wifi", "off"])
        else:
            await _run(["nmcli", "radio", "wifi", "on"])
        await asyncio.sleep(1)
        await self._collect()
