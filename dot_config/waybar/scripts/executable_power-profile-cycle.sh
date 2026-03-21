#!/usr/bin/env bash

CURRENT_MODE="$(cat /sys/firmware/acpi/platform_profile)"
case "$CURRENT_MODE" in
	"low-power")
		power-mode-balanced
		# echo balanced > /sys/firmware/acpi/platform_profile
		;;
	"balanced")
        	power-mode-performance
		# echo performance > /sys/firmware/acpi/platform_profile
		;;
	"performance")
		power-mode-low-power
		# echo low-power > /sys/firmware/acpi/platform_profile
		;;
esac
