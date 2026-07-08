#!/usr/bin/env bash

CONTROL_FILE="/sys/firmware/acpi/platform_profile"
CURRENT_MODE="$(cat $CONTROL_FILE)"
CLASS="$CURRENT_MODE"

case "$CURRENT_MODE" in
	"low-power")
		ICON=""
		;;
	"balanced")
		ICON=""
		;;
	"performance")
		ICON=""
		;;
esac
printf '{"text": "%s", "class": "%s"}\n' "$ICON" "$CLASS"
