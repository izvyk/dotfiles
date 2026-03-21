#!/usr/bin/bash

# Source https://stackoverflow.com/a/14939373
# Test for network conection
for interface in $(ls /sys/class/net/ | grep -v lo); do
  [[ "$(cat /sys/class/net/$interface/carrier)" = 1 ]] && OnLine=1
done

if ! [ $OnLine ]; then
    notify-send -u critical "Unable to turn VPN on" "Network is disconnected" -i .local/share/icons/Tela-circle/symbolic/emblems/emblem-system-symbolic.svg
    exit 1
fi

exit 0
