#!/usr/bin/bash

if $(nmcli con show --active | grep wireguard -q); then
	ICON="󱙱"
	CLASS="disabled"
else
	ICON="󰌾"
	CLASS="enabled"
fi
printf '{"text": "%s", "class": "%s"}\n' "$ICON" "$CLASS"
