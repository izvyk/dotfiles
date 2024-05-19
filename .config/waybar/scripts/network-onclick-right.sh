#!/usr/bin/bash

# Source https://stackoverflow.com/a/14939373
# Test for network conection
for interface in $(ls /sys/class/net/ | grep -v lo); do
  [[ "$(cat /sys/class/net/$interface/carrier)" = 1 ]] && OnLine=1
done

if ! [ $OnLine ]; then
    nmcli radio wifi on
fi

footclient --override=app-id=waybarnmtui -W 57x25 sh -c 'sleep 0.02 && nmtui connect'

# Update VPN module
pkill -RTMIN+8 waybar
