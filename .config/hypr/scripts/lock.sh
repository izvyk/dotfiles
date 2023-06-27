#!/usr/bin/bash

if ! $(~/.config/hypr/scripts/lock-is-private.sh); then
    touch ~/.cache/lock-private
elif [[ "$1" == "--instantly" ]]; then
    touch ~/.cache/lock-instantly-once
fi

loginctl lock-session
