#!/usr/bin/env bash
# Levish lock screen date presentation
day=$(date +"%A" | tr '[:lower:]' '[:upper:]')
d=$(date +"%d %B %Y" | tr '[:lower:]' '[:upper:]')
echo "<span weight='bold' color='#c8f7ef'>$day</span>  •  <span>$d</span>"
