#!/usr/bin/env bash
# Levish — reload.sh : restart only the Quickshell UI (backend keeps running)
set -euo pipefail

LEVISH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QS_DIR="$LEVISH_DIR/quickshell"

echo "[levish] Reloading Quickshell…"
qs kill -p "$QS_DIR" 2>/dev/null || true
sleep 0.5
qs -p "$QS_DIR" -d > /tmp/levish-quickshell.log 2>&1
echo "[levish] Done."
