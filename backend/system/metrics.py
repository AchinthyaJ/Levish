"""System metrics collection via psutil."""
import asyncio
import json
import logging
import subprocess
from pathlib import Path
from typing import Any, Dict, List, Optional

import psutil

logger = logging.getLogger(__name__)

STATE_DIR = Path("/tmp/levish")
METRICS_FILE = STATE_DIR / "metrics.json"


class SystemMetrics:
    """Polls CPU, RAM, swap, GPU, temperature, network; writes metrics.json."""

    def __init__(self, event_bus=None, interval: float = 2.0) -> None:
        self._bus = event_bus
        self._interval = interval
        self._running = False
        self._task: Optional[asyncio.Task] = None
        self._state: Dict[str, Any] = {}
        # Seed previous network counters
        try:
            net = psutil.net_io_counters()
            self._prev_bytes_sent = net.bytes_sent
            self._prev_bytes_recv = net.bytes_recv
        except Exception:
            self._prev_bytes_sent = 0
            self._prev_bytes_recv = 0

        # Pre-populate state
        try:
            self._state = self._collect_sync()
        except Exception:
            self._state = {}

    async def start(self) -> None:
        """Begin polling loop."""
        self._running = True
        self._task = asyncio.create_task(self._loop())
        logger.info("SystemMetrics started (interval=%ss)", self._interval)

    async def stop(self) -> None:
        """Stop polling loop."""
        self._running = False
        if self._task:
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass
        logger.info("SystemMetrics stopped")

    def get_state(self) -> Dict[str, Any]:
        return dict(self._state)

    async def _loop(self) -> None:
        while self._running:
            try:
                await self._collect()
            except asyncio.CancelledError:
                raise
            except Exception as exc:
                logger.error("SystemMetrics poll error: %s", exc)
            await asyncio.sleep(self._interval)

    async def _collect(self) -> None:
        loop = asyncio.get_event_loop()
        state = await loop.run_in_executor(None, self._collect_sync)
        self._state = state
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        try:
            METRICS_FILE.write_text(json.dumps(state, indent=2))
        except OSError as exc:
            logger.error("Failed to write metrics.json: %s", exc)
        if self._bus:
            await self._bus.emit("metrics_update", state)

    def _collect_sync(self) -> Dict[str, Any]:
        # CPU
        try:
            per_core: List[float] = psutil.cpu_percent(percpu=True)  # type: ignore[arg-type]
            cpu_total = sum(per_core) / len(per_core) if per_core else 0.0
        except Exception:
            per_core = []
            cpu_total = 0.0

        # RAM
        try:
            mem = psutil.virtual_memory()
            ram_percent = mem.percent
            ram_used_gb = round(mem.used / 1024**3, 2)
            ram_total_gb = round(mem.total / 1024**3, 2)
        except Exception:
            ram_percent = ram_used_gb = ram_total_gb = 0.0

        # Swap
        try:
            swap = psutil.swap_memory()
            swap_percent = swap.percent
            swap_used_gb = round(swap.used / 1024**3, 2)
            swap_total_gb = round(swap.total / 1024**3, 2)
        except Exception:
            swap_percent = swap_used_gb = swap_total_gb = 0.0

        # CPU temperature
        cpu_temp = self._get_cpu_temp()

        # GPU
        gpu_percent, gpu_vram_used, gpu_vram_total, gpu_temp = self._get_gpu_info()

        # Network
        net_up_mbps, net_down_mbps = self._get_net_speed()

        return {
            "cpu_percent": round(cpu_total, 1),
            "cpu_per_core": [round(c, 1) for c in per_core],
            "ram_percent": round(ram_percent, 1),
            "ram_used_gb": ram_used_gb,
            "ram_total_gb": ram_total_gb,
            "swap_percent": round(swap_percent, 1),
            "swap_used_gb": swap_used_gb,
            "swap_total_gb": swap_total_gb,
            "cpu_temp": cpu_temp,
            "gpu_percent": gpu_percent,
            "gpu_vram_used_gb": gpu_vram_used,
            "gpu_vram_total_gb": gpu_vram_total,
            "gpu_temp": gpu_temp,
            "net_up_mbps": net_up_mbps,
            "net_down_mbps": net_down_mbps,
        }

    def _get_cpu_temp(self) -> Optional[float]:
        try:
            temps = psutil.sensors_temperatures()
            for key in ("coretemp", "k10temp", "acpitz", "cpu_thermal"):
                if key in temps and temps[key]:
                    readings = [t.current for t in temps[key] if t.current is not None]
                    if readings:
                        return round(max(readings), 1)
        except Exception:
            pass
        # Fallback: /sys/class/thermal/thermal_zone0/temp
        try:
            raw = Path("/sys/class/thermal/thermal_zone0/temp").read_text().strip()
            return round(int(raw) / 1000.0, 1)
        except Exception:
            return None

    def _get_gpu_info(self):
        # Try NVIDIA
        try:
            result = subprocess.run(
                [
                    "nvidia-smi",
                    "--query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu",
                    "--format=csv,noheader,nounits",
                ],
                capture_output=True,
                text=True,
                timeout=3,
            )
            if result.returncode == 0 and result.stdout.strip():
                parts = [p.strip() for p in result.stdout.strip().split(",")]
                gpu_util = round(float(parts[0]), 1)
                vram_used = round(float(parts[1]) / 1024, 2)
                vram_total = round(float(parts[2]) / 1024, 2)
                g_temp = round(float(parts[3]), 1)
                return gpu_util, vram_used, vram_total, g_temp
        except Exception:
            pass

        # Try AMD/Intel via sysfs
        for card in ["card0", "card1"]:
            busy_path = Path(f"/sys/class/drm/{card}/device/gpu_busy_percent")
            if busy_path.exists():
                try:
                    gpu_util = round(float(busy_path.read_text().strip()), 1)
                    return gpu_util, None, None, None
                except Exception:
                    pass

        return None, None, None, None

    def _get_net_speed(self):
        try:
            net = psutil.net_io_counters()
            sent_delta = max(net.bytes_sent - self._prev_bytes_sent, 0)
            recv_delta = max(net.bytes_recv - self._prev_bytes_recv, 0)
            self._prev_bytes_sent = net.bytes_sent
            self._prev_bytes_recv = net.bytes_recv
            up_mbps = round(sent_delta / (1024**2) / self._interval, 3)
            down_mbps = round(recv_delta / (1024**2) / self._interval, 3)
            return up_mbps, down_mbps
        except Exception:
            return 0.0, 0.0
