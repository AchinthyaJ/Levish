#!/usr/bin/env bash
# Levish — dev.sh: backend in the foreground with debug logging, UI in the foreground.
set -euo pipefail

LEVISH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QS_DIR="$LEVISH_DIR/quickshell"

echo "[levish-dev] ━━━ Development Mode ━━━"
"$LEVISH_DIR/scripts/stop.sh" >/dev/null 2>&1 || true
mkdir -p /tmp/levish

cleanup() {
    echo ""
    echo "[levish-dev] Shutting down…"
    "$LEVISH_DIR/scripts/stop.sh" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

python3 "$LEVISH_DIR/backend/main.py" --debug &
echo "[levish-dev] Backend PID: $!"
# Quickshell runs in the foreground so its QML errors print here.
qs -p "$QS_DIR"
