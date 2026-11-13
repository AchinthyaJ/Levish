"""BlueZ Bluetooth management via dbus."""
import asyncio
import json
import logging
import re
import threading
from pathlib import Path
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)

STATE_DIR = Path("/tmp/levish")
BT_SCAN_FILE = STATE_DIR / "bt_scan.json"
BLUETOOTH_FILE = STATE_DIR / "bluetooth.json"

try:
    import dbus
    import dbus.mainloop.glib
    from gi.repository import GLib
    _DBUS_AVAILABLE = True
except ImportError:
    _DBUS_AVAILABLE = False
    logger.warning("BluetoothManager: dbus/gobject not available, using fallback mode")

BLUEZ_SERVICE = "org.bluez"
BLUEZ_ADAPTER_IFACE = "org.bluez.Adapter1"
BLUEZ_DEVICE_IFACE = "org.bluez.Device1"
DBUS_PROPERTIES_IFACE = "org.freedesktop.DBus.Properties"
DBUS_OBJECT_MANAGER_IFACE = "org.freedesktop.DBus.ObjectManager"


class BluetoothManager:
    """Bluetooth management via BlueZ dbus."""

    def __init__(self, event_bus=None) -> None:
        self._bus = event_bus
        self._running = False
        self._state: Dict[str, Any] = {"enabled": False, "devices": []}
        self._dbus_available = _DBUS_AVAILABLE
        self._poll_task: Optional[asyncio.Task] = None

    async def start(self) -> None:
        self._running = True
        await self._collect()
        self._poll_task = asyncio.create_task(self._poll_loop())
        logger.info("BluetoothManager started (dbus=%s)", self._dbus_available)

    async def stop(self) -> None:
        self._running = False
        if self._poll_task:
            self._poll_task.cancel()
            try:
                await self._poll_task
            except asyncio.CancelledError:
                pass
        logger.info("BluetoothManager stopped")

    def get_state(self) -> Dict[str, Any]:
        return dict(self._state)

    async def _poll_loop(self) -> None:
        while self._running:
            try:
                await asyncio.sleep(15)
                await self._collect()
            except asyncio.CancelledError:
                raise
            except Exception as exc:
                logger.error("BluetoothManager poll error: %s", exc)

    async def _collect(self) -> None:
        loop = asyncio.get_event_loop()
        state = await loop.run_in_executor(None, self._get_status_sync)
        self._state = state
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        try:
            BLUETOOTH_FILE.write_text(json.dumps(state, indent=2))
        except OSError as exc:
            logger.error("Failed to write bluetooth.json: %s", exc)
        if self._bus:
            await self._bus.emit("bluetooth_update", state)

    def _get_dbus_system_bus(self):
        """Get a dbus system bus instance (thread-safe, no main loop needed for queries)."""
        return dbus.SystemBus()

    def _get_status_sync(self) -> Dict[str, Any]:
        if not self._dbus_available:
            return {"enabled": False, "devices": [], "error": "dbus not available"}
        try:
            bus = self._get_dbus_system_bus()
            manager = dbus.Interface(
                bus.get_object(BLUEZ_SERVICE, "/"),
                DBUS_OBJECT_MANAGER_IFACE,
            )
            objects = manager.GetManagedObjects()

            adapter_path = None
            adapter_props: Dict[str, Any] = {}
            devices: List[Dict[str, Any]] = []

            for path, ifaces in objects.items():
                if BLUEZ_ADAPTER_IFACE in ifaces:
                    adapter_path = path
                    adapter_props = dict(ifaces[BLUEZ_ADAPTER_IFACE])

                if BLUEZ_DEVICE_IFACE in ifaces:
                    dev = dict(ifaces[BLUEZ_DEVICE_IFACE])
                    devices.append({
                        "name": str(dev.get("Name", dev.get("Address", "Unknown"))),
                        "address": str(dev.get("Address", "")),
                        "connected": bool(dev.get("Connected", False)),
                        "paired": bool(dev.get("Paired", False)),
                        "trusted": bool(dev.get("Trusted", False)),
                        "rssi": int(dev.get("RSSI", 0)) if "RSSI" in dev else None,
                    })

            enabled = bool(adapter_props.get("Powered", False))
            return {"enabled": enabled, "devices": devices}

        except Exception as exc:
            logger.debug("BluetoothManager dbus error: %s", exc)
            return {"enabled": False, "devices": [], "error": str(exc)}

    async def get_status(self) -> Dict[str, Any]:
        """Return current bluetooth status."""
        await self._collect()
        return self._state

    async def toggle_power(self) -> bool:
        """Toggle bluetooth adapter power. Returns new state."""
        loop = asyncio.get_event_loop()
        result = await loop.run_in_executor(None, self._toggle_power_sync)
        await self._collect()
        return result

    def _toggle_power_sync(self) -> bool:
        if not self._dbus_available:
            return False
        try:
            bus = self._get_dbus_system_bus()
            manager = dbus.Interface(
                bus.get_object(BLUEZ_SERVICE, "/"),
                DBUS_OBJECT_MANAGER_IFACE,
            )
            objects = manager.GetManagedObjects()
            for path, ifaces in objects.items():
                if BLUEZ_ADAPTER_IFACE in ifaces:
                    adapter = dbus.Interface(
                        bus.get_object(BLUEZ_SERVICE, path),
                        DBUS_PROPERTIES_IFACE,
                    )
                    powered = bool(adapter.Get(BLUEZ_ADAPTER_IFACE, "Powered"))
                    adapter.Set(BLUEZ_ADAPTER_IFACE, "Powered", dbus.Boolean(not powered))
                    return not powered
            return False
        except Exception as exc:
            logger.error("BluetoothManager toggle_power failed: %s", exc)
            return False

    async def connect_device(self, address: str) -> bool:
        """Connect to a paired device by MAC address."""
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(None, self._connect_device_sync, address)

    def _connect_device_sync(self, address: str) -> bool:
        if not self._dbus_available:
            return False
        try:
            bus = self._get_dbus_system_bus()
            manager = dbus.Interface(
                bus.get_object(BLUEZ_SERVICE, "/"),
                DBUS_OBJECT_MANAGER_IFACE,
            )
            objects = manager.GetManagedObjects()
            for path, ifaces in objects.items():
                if BLUEZ_DEVICE_IFACE in ifaces:
                    dev = dict(ifaces[BLUEZ_DEVICE_IFACE])
                    if str(dev.get("Address", "")) == address:
                        device = dbus.Interface(
                            bus.get_object(BLUEZ_SERVICE, path),
                            BLUEZ_DEVICE_IFACE,
                        )
                        device.Connect()
                        return True
            return False
        except Exception as exc:
            logger.error("BluetoothManager connect_device(%s) failed: %s", address, exc)
            return False

    async def disconnect_device(self, address: str) -> bool:
        """Disconnect a device by MAC address."""
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(None, self._disconnect_device_sync, address)

    def _disconnect_device_sync(self, address: str) -> bool:
        if not self._dbus_available:
            return False
        try:
            bus = self._get_dbus_system_bus()
            manager = dbus.Interface(
                bus.get_object(BLUEZ_SERVICE, "/"),
                DBUS_OBJECT_MANAGER_IFACE,
            )
            objects = manager.GetManagedObjects()
            for path, ifaces in objects.items():
                if BLUEZ_DEVICE_IFACE in ifaces:
                    dev = dict(ifaces[BLUEZ_DEVICE_IFACE])
                    if str(dev.get("Address", "")) == address:
                        device = dbus.Interface(
                            bus.get_object(BLUEZ_SERVICE, path),
                            BLUEZ_DEVICE_IFACE,
                        )
                        device.Disconnect()
                        return True
            return False
        except Exception as exc:
            logger.error("BluetoothManager disconnect_device(%s) failed: %s", address, exc)
            return False

    async def scan_devices(self, duration: float = 5.0) -> List[Dict[str, Any]]:
        """Start discovery scan and return available devices."""
        loop = asyncio.get_event_loop()
        await loop.run_in_executor(None, self._start_discovery_sync)
        await asyncio.sleep(duration)
        await loop.run_in_executor(None, self._stop_discovery_sync)
        await self._collect()
        return self._state.get("devices", [])

    def _start_discovery_sync(self) -> None:
        if not self._dbus_available:
            return
        try:
            bus = self._get_dbus_system_bus()
            manager = dbus.Interface(
                bus.get_object(BLUEZ_SERVICE, "/"),
                DBUS_OBJECT_MANAGER_IFACE,
            )
            objects = manager.GetManagedObjects()
            for path, ifaces in objects.items():
                if BLUEZ_ADAPTER_IFACE in ifaces:
                    adapter = dbus.Interface(
                        bus.get_object(BLUEZ_SERVICE, path),
                        BLUEZ_ADAPTER_IFACE,
                    )
                    adapter.StartDiscovery()
                    return
        except Exception as exc:
            logger.debug("BluetoothManager start_discovery failed: %s", exc)

    def _stop_discovery_sync(self) -> None:
        if not self._dbus_available:
            return
        try:
            bus = self._get_dbus_system_bus()
            manager = dbus.Interface(
                bus.get_object(BLUEZ_SERVICE, "/"),
                DBUS_OBJECT_MANAGER_IFACE,
            )
            objects = manager.GetManagedObjects()
            for path, ifaces in objects.items():
                if BLUEZ_ADAPTER_IFACE in ifaces:
                    adapter = dbus.Interface(
                        bus.get_object(BLUEZ_SERVICE, path),
                        BLUEZ_ADAPTER_IFACE,
                    )
                    adapter.StopDiscovery()
                    return
        except Exception as exc:
            logger.debug("BluetoothManager stop_discovery failed: %s", exc)

    async def scan_to_file(self, duration: float = 6.0) -> List[Dict[str, Any]]:
        """Discover nearby devices and publish them to bt_scan.json for the control centre."""
        devices = await self.scan_devices(duration)
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        try:
            BT_SCAN_FILE.write_text(json.dumps({"devices": devices}, indent=2))
        except OSError as exc:
            logger.error("Failed to write bt_scan.json: %s", exc)
        return devices

    async def pair_device(self, address: str) -> bool:
        """Pair, trust and connect a device through bluetoothctl, which provides the pairing agent."""
        if not re.fullmatch(r"([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}", address or ""):
            return False
        script = (
            "agent NoInputNoOutput\n"
            "default-agent\n"
            f"pair {address}\n"
            f"trust {address}\n"
            f"connect {address}\n"
            "quit\n"
        )
        try:
            proc = await asyncio.create_subprocess_exec(
                "bluetoothctl",
                stdin=asyncio.subprocess.PIPE,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.STDOUT,
            )
            out, _ = await asyncio.wait_for(proc.communicate(script.encode()), timeout=60.0)
        except (asyncio.TimeoutError, FileNotFoundError, OSError) as exc:
            logger.error("BluetoothManager pair_device(%s) failed: %s", address, exc)
            return False
        text = out.decode(errors="replace")
        paired = "Pairing successful" in text or "already paired" in text.lower()
        await self._collect()
        return paired

