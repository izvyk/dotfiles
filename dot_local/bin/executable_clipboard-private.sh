#!/usr/bin/bash

hyprctl activewindow -j | gojq -e '.initialClass == "org.keepassxc.KeePassXC"' >/dev/null || [ "$CLIPBOARD_STATE" = "sensitive" ]
