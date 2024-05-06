#!/usr/bin/bash

current_workspace_id="$(hyprctl activeworkspace -j | jq -r '.id')"
clients="$(hyprctl -j clients)"
current_workspace_clients="$(echo "$clients" | jq -r ".[] | select(.workspace.id == $current_workspace_id)")"

if $(echo "$current_workspace_clients" | jq -r "select(.class == \"firefox\").title" | grep -iq 'Firefox Private Browsing'); then
	exit 1
fi

if [[ -n "$(echo "$current_workspace_clients" | jq -r "select(.initialTitle == \"Picture-in-Picture\")")" ]]; then
	if $(echo "$clients" | jq -r ".[] | select(.class == \"firefox\").title" | grep -iq 'Firefox Private Browsing'); then
		exit 1
	fi
fi

if $(echo "$current_workspace_clients" | jq -r ".class" | grep -iq keepassxc); then
	exit 1
fi

exit 0
