#!/usr/bin/bash

#hyprctl clients | grep 'Firefox Private Browsing' -q && echo 1 || echo 0
if ! $(hyprctl clients | grep 'Firefox Private Browsing\|KeePassXC' -q)
then
	exit -1
fi
exit 0
