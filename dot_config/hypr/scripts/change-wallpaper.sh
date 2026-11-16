#!/usr/bin/env bash

HYPRLAND_CURSOR_POS="$(hyprctl cursorpos -j)"
HYPRLAND_CURSOR_X="$(echo "$HYPRLAND_CURSOR_POS" | jq '.x')"
HYPRLAND_CURSOR_Y="$(echo "$HYPRLAND_CURSOR_POS" | jq '.y')"

# ACTIVE_MONITOR="$(hyprctl monitors -j | jq 'map(select(.focused == true)) | .[0]')"
# ACTIVE_MONITOR_HEIGHT="$(echo "$ACTIVE_MONITOR" | jq '.height')"
# ACTIVE_MONITOR_SCALE="$(echo "$ACTIVE_MONITOR" | jq '.scale')"
# 2. Get Active Monitor Details (Including X and Y offsets)
ACTIVE_MONITOR="$(hyprctl monitors -j | jq 'map(select(.focused == true)) | .[0]')"
ACTIVE_MONITOR_SCALE="$(echo "$ACTIVE_MONITOR" | jq '.scale')"
ACTIVE_MONITOR_X="$(echo "$ACTIVE_MONITOR" | jq '.x')"
ACTIVE_MONITOR_Y="$(echo "$ACTIVE_MONITOR" | jq '.y')"

# 3. Calculate Relative Position
# We send: Cursor X, Cursor Y, Monitor X, Monitor Y, Scale
SWWW_POSITION="$(echo "$HYPRLAND_CURSOR_X $HYPRLAND_CURSOR_Y $ACTIVE_MONITOR_X $ACTIVE_MONITOR_Y $ACTIVE_MONITOR_SCALE" | python3 <( echo '
# Read space-separated values
c_x, c_y, m_x, m_y, scale = map(float, input().split())

# Calculate relative position inside the monitor
rel_x = c_x - m_x
rel_y = c_y - m_y

# Scale to physical pixels (swww uses physical pixels on the buffer)
final_x = int(rel_x * scale)
final_y = int(rel_y * scale)

print(f"{final_x},{final_y}")
'))"

CURRENT_WALLPAPER_PATH="$(swww query | cut -c 59-)"
NEW_WALLPAPER_PATH="$(find /home/$USER/.local/share/wallpapers/ -maxdepth 1 -type f ! -path "$CURRENT_WALLPAPER_PATH" | shuf -n1)"

ln -sf "$NEW_WALLPAPER_PATH" ~/.cache/wallpaper
swww img -t grow "$NEW_WALLPAPER_PATH" --transition-pos "$SWWW_POSITION" --transition-fps 60
