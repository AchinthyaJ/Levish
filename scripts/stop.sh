#!/usr/bin/env bash
# Levish — stop.sh
set -euo pipefail

LEVISH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QS_DIR="$LEVISH_DIR/quickshell"

echo "[levish] Stopping…"
pkill -f "$LEVISH_DIR/backend/main.py"         2>/dev/null && echo "  Backend stopped"      || true
pkill -f "$LEVISH_DIR/scripts/osd_listener.py" 2>/dev/null && echo "  OSD listener stopped" || true
qs kill -p "$QS_DIR" 2>/dev/null && echo "  Quickshell stopped"  || true
# Force-stop any leftover Quickshell instance for this config
pkill -f "^qs -p $QS_DIR" 2>/dev/null && echo "  Quickshell force-stopped" || true
rm -f /tmp/levish/backend.pid /tmp/levish/hover-*
echo "[levish] Done."
