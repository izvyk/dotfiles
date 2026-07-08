#!/usr/bin/env bash

current_workspace_id="$(hyprctl activeworkspace -j | jq -r '.id')"
clients="$(hyprctl -j clients)"
current_workspace_clients="$(echo "$clients" | jq -r "[.[] | select(.workspace.id == $current_workspace_id)]")"

firefox_incognito="$(echo "$clients" | jq -er '[.[] | select((.initialClass == "firefox") and (.title | endswith("Mozilla Firefox Private Browsing")))]')"
if [ -n "$firefox_incognito" ]; then
    if  $(echo "$firefox_incognito" | jq -er ".|any(.workspace.id == $current_workspace_id)") >/dev/null ||
        $(echo "$current_workspace_clients" | jq -re '.|any(.initialTitle == "Picture-in-Picture")') >/dev/null; then
            exit 0
    fi
fi

if $(echo "$current_workspace_clients" | jq -re '.|any(.initialClass == "org.keepassxc.KeePassXC")') >/dev/null; then
	exit 0
fi

exit 1
