#!/usr/bin/env bash

hyprctl activewindow -j | jq -e '.initialClass == "org.keepassxc.KeePassXC"' >/dev/null || [ "$CLIPBOARD_STATE" = "sensitive" ]
