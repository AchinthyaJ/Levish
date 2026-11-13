#!/usr/bin/env bash
# =============================================================
# Levish — launch.sh
# Start the backend (metrics, Hyprland state files) and the Quickshell UI.
# =============================================================
set -euo pipefail

LEVISH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QS_DIR="$LEVISH_DIR/quickshell"
BACKEND="$LEVISH_DIR/backend/main.py"
OSD="$LEVISH_DIR/scripts/osd_listener.py"
LOG_BACK="/tmp/levish-backend.log"
LOG_OSD="/tmp/levish-osd.log"
LOG_QS="/tmp/levish-quickshell.log"

echo "[levish] ━━━ Starting Levish ━━━"

# ── Stop any existing instances ───────────────────────────────
"$LEVISH_DIR/scripts/stop.sh" >/dev/null 2>&1 || true

# ── Runtime directory ─────────────────────────────────────────
mkdir -p /tmp/levish

# ── Start backend ─────────────────────────────────────────────
python3 "$BACKEND" > "$LOG_BACK" 2>&1 &
echo "[levish] Backend started (PID $!) — log: $LOG_BACK"

# ── Start Quickshell UI (bar + panels) ────────────────────────
qs -p "$QS_DIR" -d > "$LOG_QS" 2>&1
echo "[levish] Quickshell started — log: $LOG_QS"

# ── Start OSD listener ───────────────────────────────────────
python3 "$OSD" > "$LOG_OSD" 2>&1 &
echo "[levish] OSD listener started (PID $!)"

echo "[levish] ━━━ Levish is running ━━━"
echo "  Stop with: $LEVISH_DIR/scripts/stop.sh"
