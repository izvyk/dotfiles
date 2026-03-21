#!/usr/bin/bash

nmcli -t con show --active | rg -e "vpn|wireguard" -q
