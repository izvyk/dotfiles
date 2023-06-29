#!/usr/bin/bash

if $(nmcli con show --active | grep wireguard -q); then
	ICON="󰌾"
	CLASS="enabled"
else
	ICON="󱙱"
	CLASS="disabled"
fi
printf '{"text": "%s", "class": "%s"}\n' "$ICON" "$CLASS"
