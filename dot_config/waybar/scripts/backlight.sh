#!/usr/bin/bash

REAL_BRIGHTNESS="$(brightnessctl -m i | cut -d ',' -f 4 | head -c -2)"
#["󰃞 ", "󰃟 ", "󰃠 "]
if [[ "$REAL_BRIGHTNESS" == "0" ]]; then
	CLASS="virtual"
	ICON="󰃝"
	VIRTUAL_BRIGHTNESS="$(( "$(busctl --user get-property rs.wl-gammarelay / rs.wl.gammarelay Brightness | cut -d ' ' -f 2 | sed 's/\./,/g')" * 100 ))"

	#TEXT="$(( 100 - "$VIRTUAL_BRIGHTNESS" ))"%
	TEXT="$VIRTUAL_BRIGHTNESS"
else
	CLASS="real"
	TEXT="$REAL_BRIGHTNESS"%
	if (( "$REAL_BRIGHTNESS" < 33 )); then
		ICON="󰃞"
	elif (( "$REAL_BRIGHTNESS" < 66 )); then
		ICON="󰃟"
	else
		ICON="󰃠"
	fi
fi
printf '{"text": "%s", "icon": "%s", "class": "%s"}\n' "$ICON  $TEXT" "$CLASS"
