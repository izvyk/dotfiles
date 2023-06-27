#!/usr/bin/bash

PRIVATELOCK_FILE=~/.cache/lock-private

if [[ -f "$PRIVATELOCK_FILE" ]]; then
    rm "$PRIVATELOCK_FILE"
    exit 1
fi

exit 0
