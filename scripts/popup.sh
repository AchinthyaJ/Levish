#!/usr/bin/env bash
# Levish — popup.sh
# Hover-driven popups. Usage: popup.sh <enter|leave> <name>
#   name = dashboard | controls
# A popup opens when the pointer enters its trigger island or the popup
# itself. On leave it closes after a short grace period, unless the pointer
# has moved onto the popup in the meantime (so moving down into it works).
set -euo pipefail

LEVISH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EWW_CFG="$LEVISH_DIR/eww"
STATE_DIR="/tmp/levish"
GRACE_SECONDS="0.4"

action="${1:?usage: popup.sh <enter|leave> <name>}"
name="${2:?usage: popup.sh <enter|leave> <name>}"
window="levish-$name"
flag="$STATE_DIR/hover-$name"

mkdir -p "$STATE_DIR"

is_open() {
    eww active-windows --config "$EWW_CFG" 2>/dev/null | grep -q "^$window:"
}

case "$action" in
    enter)
        echo 1 > "$flag"
        # Only open when it is not already open: re-opening an open window is
        # what caused the flicker on repeated hover events.
        is_open || eww open "$window" --config "$EWW_CFG" >/dev/null 2>&1 || true
        [[ "$name" == "dashboard" ]] && eww update dash-open=true --config "$EWW_CFG" >/dev/null 2>&1 || true
        ;;
    leave)
        echo 0 > "$flag"
        (
            sleep "$GRACE_SECONDS"
            if [[ "$(cat "$flag" 2>/dev/null)" != "1" ]] && is_open; then
                if [[ "$name" == "dashboard" ]]; then
                    eww update dash-open=false --config "$EWW_CFG" >/dev/null 2>&1 || true
                    sleep 0.35   # let the slide-out finish before closing
                fi
                eww close "$window" --config "$EWW_CFG" >/dev/null 2>&1 || true
            fi
        ) &
        ;;
    *)
        echo "unknown action: $action" >&2
        exit 2
        ;;
esac
