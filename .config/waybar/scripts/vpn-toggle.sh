#!/usr/bin/bash

CONNECTION_NAME="$(nmcli -f NAME,TIMESTAMP,TYPE con show | grep -e 'vpn\|wireguard' | sort -nk 2 | tail -n 1 | cut -d ' ' -f 1)"

#if $(nmcli con show --active | grep wireguard -q); then
if [[ -n "$(nmcli -g GENERAL.STATE c s ${CONNECTION_NAME})" ]]; then
    nmcli con down "$CONNECTION_NAME"
else
    nmcli con up "$CONNECTION_NAME"
fi
