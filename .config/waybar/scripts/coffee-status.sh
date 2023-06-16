#!/usr/bin/bash

if [[ "$(pidof swayidle)" ]]; then
	ICON="󰾪"
	CLASS="disabled"
else
	ICON="󰅶"
	CLASS="enabled"
fi
printf '{"text": "%s", "class": "%s"}\n' "$ICON" "$CLASS"
