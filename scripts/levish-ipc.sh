#!/usr/bin/env bash
# Sends one Levish shell action to the running Quickshell instance. Hyprland keybinds call this.
#   scripts/levish-ipc.sh toggleLauncher
set -euo pipefail
LEVISH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec qs -p "$LEVISH_DIR/quickshell" ipc call levish "$1"
