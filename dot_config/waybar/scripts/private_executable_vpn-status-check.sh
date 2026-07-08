#!/usr/bin/env bash

nmcli -t con show --active | grep -e "vpn|wireguard" -q
