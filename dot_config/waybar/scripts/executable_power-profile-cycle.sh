#!/usr/bin/bash

CURRENT_MODE="$(cat /sys/firmware/acpi/platform_profile)"
case "$CURRENT_MODE" in
	"low-power")
		power-mode-balanced
		;;
	"balanced")
        power-mode-performance
		;;
	"performance")
		power-mode-low-power
		;;
esac
