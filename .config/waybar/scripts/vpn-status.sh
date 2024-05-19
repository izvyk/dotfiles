#!/usr/bin/bash

if $(nmcli con show --active | grep -e "vpn\|wireguard" -q); then
	ICON="󰌾"
	CLASS="enabled"
else
	ICON="󱙱"
	CLASS="disabled"
fi

CONNECTION_NAME="$(nmcli con show --active | grep -e 'vpn\|wireguard' | cut -d' ' -f1)"
if [ -n "$CONNECTION_NAME" ]; then CONNECTION_NAME="Name: $CONNECTION_NAME"; fi

printf '{"text": "%s", "class": "%s", "tooltip": "%s"}\n' "$ICON" "$CLASS" "$CONNECTION_NAME"
