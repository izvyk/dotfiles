#!/usr/bin/bash

HYPRLAND_CURSOR_POS="$(hyprctl cursorpos -j)"
HYPRLAND_CURSOR_X="$(echo "$HYPRLAND_CURSOR_POS" | gojq '.x')"
HYPRLAND_CURSOR_Y="$(echo "$HYPRLAND_CURSOR_POS" | gojq '.y')"

ACTIVE_MONITOR="$(hyprctl monitors -j | gojq 'map(select(.focused == true)) | .[0]')"
ACTIVE_MONITOR_HEIGHT="$(echo "$ACTIVE_MONITOR" | gojq '.height')"
ACTIVE_MONITOR_SCALE="$(echo "$ACTIVE_MONITOR" | gojq '.scale')"

SWWW_POSITION="$(echo "$HYPRLAND_CURSOR_X $HYPRLAND_CURSOR_Y $ACTIVE_MONITOR_SCALE $ACTIVE_MONITOR_HEIGHT" | python <( echo '
x, y, scale, height = map(float, input().split())
print(int(x * scale), int(height - y * scale), sep=",")
'))"

CURRENT_WALLPAPER_PATH="$(swww query | cut -c 59-)"
NEW_WALLPAPER_PATH="$(find /home/$USER/.local/share/wallpapers/ -maxdepth 1 -type f ! -path "$CURRENT_WALLPAPER_PATH" | shuf -n1)"

ln -sf "$NEW_WALLPAPER_PATH" ~/.cache/wallpaper
swww img -t grow "$NEW_WALLPAPER_PATH" --transition-pos "$SWWW_POSITION" --transition-fps 60
