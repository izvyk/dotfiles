#!/usr/bin/bash

SCRIPT_PATH="$(dirname "$0")"
VPN_REGEX="vpn|wireguard"

# If a VPN is enabled, network is up and no further check is needed
# Otherwise, check if network is up and exit if it's not
"$SCRIPT_PATH"/vpn-status-check.sh || "$SCRIPT_PATH"/vpn-check-network.sh || exit 1

# List of all VPNs in the MRU order
CONNECTIONS="$(nmcli -t -f NAME,TIMESTAMP,TYPE con show | rg -e "$VPN_REGEX" | sort -nk 2 | cut -d ':' -f 1)"

# Use Rofi if such a flag provided or use the most recently used one
if [ "$1" = "--interactive" ]; then
    ROFI_CMD="rofi -dmenu -p \"VPN\""

    ACTIVE="$(nmcli -t con show --active | rg -e "$VPN_REGEX")"
    [ "$?" = 0 ] && ROFI_CMD="$ROFI_CMD -mesg \"Active: ${ACTIVE%%:*}\""

    CONNECTION_NAME="$(echo "$CONNECTIONS" | eval "$ROFI_CMD")"

    # Exit if Rofi was closed without choosing an entry
    [ -z "$CONNECTION_NAME" ] && exit
else
    CONNECTION_NAME="$(echo "$CONNECTIONS" | tail -n 1)"
fi

# Remember the status of the chosen connection
CONNECTION_STATUS="$(nmcli -g GENERAL.STATE c s "$CONNECTION_NAME")"

# Turn off every VPN connection. We don't want multiple VPNs at once
while IFS= read -r CON; do
    nmcli con down "$CON" 2>/dev/null
done <<< "$CONNECTIONS"

# Turn it on if it was off originally
[ -z "$CONNECTION_STATUS" ] && nmcli con up "$CONNECTION_NAME"

pkill -RTMIN+8 waybar
