#!/usr/bin/bash

CURRENT_MODE="$(cat /sys/firmware/acpi/platform_profile)"
case "$CURRENT_MODE" in
	"low-power")
		doas /etc/bin/power-mode-balanced
		;;
	"balanced")
		doas /etc/bin/power-mode-performance
		;;
	"performance")
		doas /etc/bin/power-mode-low-power
		;;
esac
