#!/usr/bin/env python3
"""Levish backend main process — orchestrates all subsystems."""
import asyncio
import json
import logging
import os
import signal
import sys
import argparse
from pathlib import Path

# Add backend dir to path
sys.path.insert(0, str(Path(__file__).parent))

from config import Config, PinnedApps
from events import EventBus
from system.metrics import SystemMetrics
from system.battery import BatteryMonitor
from hyprland.ipc import HyprlandIPC
from audio.pipewire import AudioManager
from network.nm import NetworkManager as NMManager
from bluetooth.bluez import BluetoothManager
from media.mpris import MediaPlayer
from power.power import PowerManager
from power.profiles import PowerProfileManager
from applications.apps import ApplicationManager
from brightness import BrightnessManager

STATE_DIR = Path("/tmp/levish")
PID_FILE = STATE_DIR / "levish.pid"
CONTROL_SOCK = STATE_DIR / "control.sock"

logger = logging.getLogger("levish.main")


def _setup_logging(debug: bool) -> None:
    level = logging.DEBUG if debug else logging.INFO
    fmt = "%(asctime)s [%(levelname)s] %(name)s: %(message)s"
    logging.basicConfig(level=level, format=fmt, stream=sys.stderr)


def _write_pid() -> None:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    PID_FILE.write_text(str(os.getpid()))


def _remove_pid() -> None:
    try:
        PID_FILE.unlink(missing_ok=True)
    except Exception:
        pass


class LevishBackend:
    """Orchestrates all Levish backend modules."""

    def __init__(self, config: Config, pinned: PinnedApps) -> None:
        self.config = config
        self.pinned = pinned
        self.bus = EventBus()
        self._running = False
        self._tasks: list = []

        # Subsystem instances
        interval = config.get("metrics_interval", 2)
        self.metrics = SystemMetrics(self.bus, interval=float(interval))
        self.battery = BatteryMonitor(self.bus)
        self.hyprland = HyprlandIPC(self.bus)
        self.audio = AudioManager(self.bus)
        self.network = NMManager(self.bus)
        self.bluetooth = BluetoothManager(self.bus)
        self.media = MediaPlayer(self.bus)
        self.power = PowerManager()
        self.apps = ApplicationManager(self.bus, pinned)
        self.brightness = BrightnessManager(self.bus)
        self.profiles = PowerProfileManager(self.bus)

    async def start(self) -> None:
        """Start all subsystems."""
        self._running = True
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        logger.info("Starting Levish backend (pid=%d)", os.getpid())

        # Start all modules concurrently
        starts = [
            self.metrics.start(),
            self.battery.start(),
            self.hyprland.start(),
            self.audio.start(),
            self.network.start(),
            self.bluetooth.start(),
            self.media.start(),
            self.brightness.start(),
            self.profiles.start(),
        ]
        results = await asyncio.gather(*starts, return_exceptions=True)
        for i, r in enumerate(results):
            if isinstance(r, Exception):
                logger.error("Module %d start error: %s", i, r)

        logger.info("All subsystems started")

    async def stop(self) -> None:
        """Stop all subsystems gracefully."""
        logger.info("Stopping Levish backend…")
        self._running = False

        stops = [
            self.metrics.stop(),
            self.battery.stop(),
            self.hyprland.stop(),
            self.audio.stop(),
            self.network.stop(),
            self.bluetooth.stop(),
            self.media.stop(),
            self.brightness.stop(),
            self.profiles.stop(),
        ]
        await asyncio.gather(*stops, return_exceptions=True)
        logger.info("All subsystems stopped")

    async def handle_command(self, cmd_data: dict) -> dict:
        """Handle a control socket command and return a response dict."""
        cmd = cmd_data.get("cmd", "")
        try:
            if cmd == "get":
                key = cmd_data.get("key", "")
                return await self._handle_get(key)
            elif cmd == "action":
                action = cmd_data.get("action", "")
                value = cmd_data.get("value")
                return await self._handle_action(action, value)
            else:
                return {"error": f"Unknown command: {cmd}"}
        except Exception as exc:
            logger.error("Command handler error: %s", exc)
            return {"error": str(exc)}

    async def _handle_get(self, key: str) -> dict:
        """Return current state for the given key."""
        if key == "workspaces":
            ws_file = STATE_DIR / "workspaces.json"
            if ws_file.exists():
                return {"workspaces": json.loads(ws_file.read_text())}
            return {"workspaces": []}
        elif key == "metrics":
            return {"metrics": self.metrics.get_state()}
        elif key == "battery":
            return {"battery": self.battery.get_state()}
        elif key == "network":
            return {"network": self.network.get_state()}
        elif key == "bluetooth":
            return {"bluetooth": self.bluetooth.get_state()}
        elif key == "media":
            return {"media": self.media.get_state()}
        elif key == "audio":
            audio_file = STATE_DIR / "audio.json"
            if audio_file.exists():
                return {"audio": json.loads(audio_file.read_text())}
            return {"audio": {}}
        elif key == "brightness":
            brightness_file = STATE_DIR / "brightness.json"
            if brightness_file.exists():
                return {"brightness": json.loads(brightness_file.read_text())}
            return {"brightness": {}}
        elif key == "apps":
            apps = await self.apps.get_apps()
            return {"apps": apps}
        elif key == "active_window":
            win_file = STATE_DIR / "active_window.json"
            if win_file.exists():
                return {"active_window": json.loads(win_file.read_text())}
            return {"active_window": {}}
        elif key == "config":
            return {"config": self.config.all()}
        else:
            return {"error": f"Unknown key: {key}"}

    async def _handle_action(self, action: str, value=None) -> dict:
        """Execute an action and return result."""
        if action == "play_pause":
            await self.media.play_pause()
            return {"ok": True}
        elif action == "next":
            await self.media.next()
            return {"ok": True}
        elif action == "previous":
            await self.media.previous()
            return {"ok": True}
        elif action == "set_volume":
            if value is not None:
                await self.audio.set_volume(int(value))
            return {"ok": True}
        elif action == "toggle_mute":
            await self.audio.toggle_mute()
            return {"ok": True}
        elif action == "set_brightness":
            if value is not None:
                await self.brightness.set_brightness(int(value))
            return {"ok": True}
        elif action == "adjust_brightness":
            if value is not None:
                new_val = await self.brightness.adjust(int(value))
                return {"ok": True, "brightness": new_val}
            return {"ok": False, "error": "value required"}
        elif action == "lock":
            ok, msg = await self.power.lock()
            return {"ok": ok, "message": msg}
        elif action == "suspend":
            ok, msg = await self.power.suspend()
            return {"ok": ok, "message": msg}
        elif action == "restart":
            ok, msg = await self.power.restart()
            return {"ok": ok, "message": msg}
        elif action == "shutdown":
            ok, msg = await self.power.shutdown()
            return {"ok": ok, "message": msg}
        elif action == "logout":
            ok, msg = await self.power.logout()
            return {"ok": ok, "message": msg}
        elif action == "switch_workspace":
            if value is not None:
                await self.hyprland.switch_workspace(int(value))
            return {"ok": True}
        elif action == "toggle_wifi":
            await self.network.toggle_wifi()
            return {"ok": True}
        elif action == "toggle_bluetooth":
            enabled = await self.bluetooth.toggle_power()
            return {"ok": True, "enabled": enabled}
        elif action == "connect_wifi":
            ssid = value.get("ssid") if isinstance(value, dict) else str(value)
            password = value.get("password") if isinstance(value, dict) else None
            ok = await self.network.connect_wifi(ssid, password)
            return {"ok": ok}
        elif action == "launch_app":
            exec_str = str(value) if value else ""
            if exec_str:
                ok = await self.apps.launch(exec_str)
                return {"ok": ok}
            return {"ok": False, "error": "exec required"}
        elif action == "search_apps":
            query = str(value) if value else ""
            results = await self.apps.search(query)
            return {"apps": results}
        elif action == "wifi_scan":
            networks = await self.network.scan_to_file()
            return {"ok": True, "count": len(networks)}
        elif action == "bt_scan":
            devices = await self.bluetooth.scan_to_file()
            return {"ok": True, "count": len(devices)}
        elif action == "bt_pair":
            ok = await self.bluetooth.pair_device(str(value or ""))
            return {"ok": ok}
        elif action == "bt_connect":
            ok = await self.bluetooth.connect_device(str(value or ""))
            return {"ok": ok}
        elif action == "bt_disconnect":
            ok = await self.bluetooth.disconnect_device(str(value or ""))
            return {"ok": ok}
        elif action == "power_profile":
            ok = await self.profiles.set_profile(str(value or ""))
            return {"ok": ok}
        elif action == "reload_config":
            self.config.reload()
            return {"ok": True}
        else:
            return {"error": f"Unknown action: {action}"}


async def _control_socket_server(backend: LevishBackend) -> None:
    """Unix socket server for control commands."""
    # Remove stale socket
    if CONTROL_SOCK.exists():
        CONTROL_SOCK.unlink()

    async def handle_client(reader: asyncio.StreamReader, writer: asyncio.StreamWriter) -> None:
        try:
            data = await asyncio.wait_for(reader.read(65536), timeout=5.0)
            if not data:
                return
            cmd_data = json.loads(data.decode())
            response = await backend.handle_command(cmd_data)
            writer.write(json.dumps(response).encode())
            await writer.drain()
        except (json.JSONDecodeError, asyncio.TimeoutError) as exc:
            try:
                writer.write(json.dumps({"error": str(exc)}).encode())
                await writer.drain()
            except Exception:
                pass
        except Exception as exc:
            logger.error("Control socket client error: %s", exc)
        finally:
            try:
                writer.close()
                await writer.wait_closed()
            except Exception:
                pass

    server = await asyncio.start_unix_server(
        handle_client, path=str(CONTROL_SOCK)
    )
    logger.info("Control socket: %s", CONTROL_SOCK)
    async with server:
        await server.serve_forever()


async def _run_backend(debug: bool) -> None:
    _setup_logging(debug)
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    _write_pid()

    config = Config()
    pinned = PinnedApps()
    backend = LevishBackend(config, pinned)

    loop = asyncio.get_event_loop()
    stop_event = asyncio.Event()

    def _signal_handler(sig, frame=None):
        logger.info("Received signal %s — shutting down", sig)
        loop.call_soon_threadsafe(stop_event.set)

    for sig in (signal.SIGTERM, signal.SIGINT):
        try:
            loop.add_signal_handler(sig, _signal_handler, sig)
        except (NotImplementedError, RuntimeError):
            signal.signal(sig, _signal_handler)

    try:
        await backend.start()

        # Run control socket and backend concurrently
        ctrl_task = asyncio.create_task(_control_socket_server(backend))
        stop_task = asyncio.create_task(stop_event.wait())

        logger.info("Levish backend running. PID file: %s", PID_FILE)

        done, pending = await asyncio.wait(
            [ctrl_task, stop_task],
            return_when=asyncio.FIRST_COMPLETED,
        )
        for task in pending:
            task.cancel()
            try:
                await task
            except asyncio.CancelledError:
                pass

    finally:
        await backend.stop()
        _remove_pid()
        # Clean up control socket
        try:
            CONTROL_SOCK.unlink(missing_ok=True)
        except Exception:
            pass
        logger.info("Levish backend exited cleanly")


def main() -> None:
    parser = argparse.ArgumentParser(description="Levish desktop shell backend")
    parser.add_argument("--debug", action="store_true", help="Enable debug logging")
    args = parser.parse_args()

    try:
        asyncio.run(_run_backend(args.debug))
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
