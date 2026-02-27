#!/usr/bin/bash

current_workspace_id="$(hyprctl activeworkspace -j | gojq -r '.id')"
clients="$(hyprctl -j clients)"
current_workspace_clients="$(echo "$clients" | gojq -r "[.[] | select(.workspace.id == $current_workspace_id)]")"

firefox_incognito="$(echo "$clients" | gojq -er '[.[] | select((.initialClass == "firefox") and (.title | endswith("Mozilla Firefox Private Browsing")))]')"
if [ -n "$firefox_incognito" ]; then
    if  $(echo "$firefox_incognito" | gojq -er ".|any(.workspace.id == $current_workspace_id)") >/dev/null ||
        $(echo "$current_workspace_clients" | gojq -re '.|any(.initialTitle == "Picture-in-Picture")') >/dev/null; then
            exit 0
    fi
fi

if $(echo "$current_workspace_clients" | gojq -re '.|any(.initialClass == "org.keepassxc.KeePassXC")') >/dev/null; then
	exit 0
fi

exit 1
