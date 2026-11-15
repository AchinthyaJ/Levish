#!/usr/bin/env bash
# Levish lock screen weather presentation
wfile="/tmp/levish/weather.json"
if [ ! -f "$wfile" ]; then
    echo "<span color='#c8f7ef'>26°C</span>  •  Partly Cloudy"
    exit 0
fi

python3 -c "
import json
try:
    d = json.load(open('$wfile'))
    t = d.get('temp_c', '--')
    c = d.get('condition', 'Clear')
    l = d.get('location', '')
    loc_str = f'  ({l})' if l else ''
    print(f\"<span color='#c8f7ef' weight='bold'>{t}°C</span>  •  <span>{c}</span><span color='#8fa6bd'>{loc_str}</span>\")
except Exception:
    print(\"<span color='#c8f7ef'>26°C</span>  •  Partly Cloudy\")
"
