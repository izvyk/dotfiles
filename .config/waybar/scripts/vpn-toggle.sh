#!/usr/bin/bash

# Source https://stackoverflow.com/a/14939373
# Test for network conection
for interface in $(ls /sys/class/net/ | grep -v lo); do
  [[ "$(cat /sys/class/net/$interface/carrier)" = 1 ]] && OnLine=1
done

if ! [ $OnLine ]; then
    notify-send -u critical "Unable to turn VPN on" "Network is disconnected" -i .local/share/icons/Tela-circle/symbolic/emblems/emblem-system-symbolic.svg
    exit
fi

CONNECTION_NAME="$(nmcli -f NAME,TIMESTAMP,TYPE con show | grep -e 'vpn\|wireguard' | sort -nk 2 | tail -n 1 | cut -d ' ' -f 1)"

#if $(nmcli con show --active | grep wireguard -q); then
if [[ -n "$(nmcli -g GENERAL.STATE c s ${CONNECTION_NAME})" ]]; then
    nmcli con down "$CONNECTION_NAME"
else
    nmcli con up "$CONNECTION_NAME"
fi

pkill -RTMIN+8 waybar
