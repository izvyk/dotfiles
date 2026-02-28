#!/usr/bin/bash

INSTANTLOCK_FILE=~/.cache/lock-instantly-once

if [[ -f "$INSTANTLOCK_FILE" ]]; then
    rm "$INSTANTLOCK_FILE"
    exit 1
fi

if [[ "$(/usr/bin/systemctl --user is-active sleep.target)" == "active" ]]; then
    exit 1
fi

exit 0
