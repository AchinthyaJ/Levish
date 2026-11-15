#!/usr/bin/env bash
# Levish — stop.sh
set -euo pipefail

LEVISH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QS_DIR="$LEVISH_DIR/quickshell"

echo "[levish] Stopping…"
systemctl --user stop levish-backend 2>/dev/null || true
pkill -f "$LEVISH_DIR/backend/main.py"         2>/dev/null && echo "  Backend stopped"      || true
qs kill -p "$QS_DIR" 2>/dev/null && echo "  Quickshell stopped"  || true
# Force-stop any leftover Quickshell instance for this config
pkill -f "^qs -p $QS_DIR" 2>/dev/null && echo "  Quickshell force-stopped" || true
rm -f /tmp/levish/control.sock /tmp/levish/levish.pid /tmp/levish/backend.pid /tmp/levish/hover-*
echo "[levish] Done."
