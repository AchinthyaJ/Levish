#!/usr/bin/env bash
# Levish lock screen media playback presentation
mfile="/tmp/levish/media.json"

python3 -c "
import json, os
try:
    if os.path.exists('$mfile'):
        m = json.load(open('$mfile'))
        if m.get('player'):
            t = m.get('title', '')[:32]
            a = m.get('artist', '')[:24]
            if t:
                by = f' — {a}' if a else ''
                print(f\"<span color='#c8f7ef'> </span> <span>{t}{by}</span>\")
                exit(0)
except Exception:
    pass
print('')
"
