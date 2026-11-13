#!/usr/bin/env bash
# Levish — build-css.sh
# Compiles eww/styles/eww.scss -> eww/eww.css with dart-sass.
# eww's built-in SCSS compiler silently drops rules, so we ship plain CSS.
set -euo pipefail

LEVISH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$LEVISH_DIR/eww/styles/eww.scss"
OUT="$LEVISH_DIR/eww/eww.css"

if ! command -v sass &>/dev/null; then
    echo "[levish] error: 'sass' (dart-sass) not found. Install it: sudo pacman -S dart-sass" >&2
    exit 1
fi

sass --no-source-map --style=expanded "$SRC" "$OUT"
echo "[levish] CSS built: $OUT"
