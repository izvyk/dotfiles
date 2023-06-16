#!/usr/bin/bash

if [[ "$(dunstctl is-paused)" == "true" ]]; then
	ICON="󰂛"
	CLASS="disabled"
else
	ICON="󰂚"
	CLASS="enabled"
fi
printf '{"text": "%s", "class": "%s"}\n' "$ICON" "$CLASS"
