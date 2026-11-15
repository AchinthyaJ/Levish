#!/usr/bin/env bash
# Levish lock screen battery & network presentation
bfile="/tmp/levish/battery.json"
nfile="/tmp/levish/network.json"

python3 -c "
import json, os
try:
    bp = 100
    ch = False
    if os.path.exists('$bfile'):
        b = json.load(open('$bfile'))
        bp = b.get('percent', 100)
        ch = b.get('charging', False)
    
    ssid = 'Wi-Fi'
    if os.path.exists('$nfile'):
        n = json.load(open('$nfile'))
        ssid = n.get('ssid', 'Connected') if n.get('connected') else 'Disconnected'

    b_icon = '⚡ ' if ch else '󰁹 '
    b_color = '#34d399' if ch else ('#f0708a' if bp <= 15 else '#c8f7ef')
    print(f\"<span color='{b_color}'>{b_icon}{bp}%</span>   •   <span color='#9fb0c6'>󰖩 {ssid}</span>\")
except Exception:
    print(\"<span color='#c8f7ef'>󰁹 100%</span>   •   <span color='#9fb0c6'>󰖩 Online</span>\")
"
