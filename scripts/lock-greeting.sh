#!/usr/bin/env bash
# Levish lock screen greeting and user name
h=$(date +"%H")
h=$((10#$h))
if [ $h -ge 5 ] && [ $h -lt 12 ]; then
    g="Good morning"
elif [ $h -ge 12 ] && [ $h -lt 17 ]; then
    g="Good afternoon"
elif [ $h -ge 17 ] && [ $h -lt 22 ]; then
    g="Good evening"
else
    g="Welcome back"
fi

u="${USER:-user}"
# Try to get display name from GECOS
name=$(getent passwd "$u" 2>/dev/null | cut -d: -f5 | cut -d, -f1)
if [ -z "$name" ]; then
    name="$u"
fi

echo "<span color='#c8f7ef'>$g,</span> <span weight='bold'>$name</span>"
