#!/usr/bin/bash

if $(systemctl --user is-active inhibitor-lock@coffee.service -q); then
	ICON="󰅶"
	CLASS="enabled"
else
	ICON="󰾪"
	CLASS="disabled"
fi
printf '{"text": "%s", "class": "%s"}\n' "$ICON" "$CLASS"
