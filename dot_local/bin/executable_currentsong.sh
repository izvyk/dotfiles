#!/usr/bin/sh

#echo "$(playerctl metadata --format '{{title}} 󰎆  {{artist}}')"
playing="$(playerctl -s metadata --format '{{title}} 󰽱  {{artist}}')"
maxlength="$1"

if [ "$maxlength" == "" ] || [ "${#playing}" -lt "$maxlength" ]; then
    echo "$playing";
else
    echo "${playing:0:$maxlength}…";
fi
