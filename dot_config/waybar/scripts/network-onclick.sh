#!/usr/bin/bash

[ "$(nmcli radio wifi)" = enabled ] && nmcli radio wifi off || nmcli radio wifi on

# Update VPN module
pkill -RTMIN+8 waybar
