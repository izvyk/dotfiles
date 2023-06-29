#!/usr/bin/bash

CONNECTION_NAME="$(nmcli con show | grep wireguard | cut -d' ' -f1)"

if $(nmcli con show --active | grep wireguard -q); then
    nmcli con down "$CONNECTION_NAME"
else
    nmcli con up "$CONNECTION_NAME"
fi
