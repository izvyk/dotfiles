#!/usr/bin/env bash

## Author : Aditya Shakya (adi1090x)
## Github : @adi1090x
#
## Rofi   : Power Menu
#
## Available Styles
#
## style-1   style-2   style-3   style-4   style-5

# Current Theme
dir="$HOME/.config/rofi/powermenu/"
#theme='style-1'

# CMDs
uptime="`uptime -p | sed -e 's/up //g'`"
host=`cat /etc/hostname `

# Options
shutdown='  Shutdown'
hibernate='  Hibernate'
reboot_arch='  Reboot to Arch'
reboot_windows='  Reboot to Windows'
lock='  Lock'
suspend='  Suspend'
logout='  Logout'
yes='  Yes'
no='  No'

# Rofi CMD
rofi_cmd() {
	rofi -dmenu \
		-p "$host" \
		-mesg "Uptime: $uptime" \
        -i \
		-theme ~/playground/theme.css
		#-theme ${dir}/${theme}.rasi
}

# Confirmation CMD
# confirm_cmd() {
# 	rofi -theme-str 'window {location: center; anchor: center; fullscreen: false; width: 250px;}' \
# 		-theme-str 'mainbox {children: [ "message", "listview" ];}' \
# 		-theme-str 'listview {columns: 2; lines: 1;}' \
# 		-theme-str 'element-text {horizontal-align: 0.5;}' \
# 		-theme-str 'textbox {horizontal-align: 0.5;}' \
# 		-dmenu \
# 		-p 'Confirmation' \
# 		-mesg 'Are you sure?' \
# 		#-theme ${dir}/${theme}.rasi
# }

confirm_cmd() {
	rofi \
		-theme-str 'mainbox {children: [ "message", "listview" ];}' \
		-dmenu \
		-p 'Confirmation' \
		-mesg 'Are you sure?' \
        -i
		#-theme ${dir}/${theme}.rasi
}

# Ask for confirmation
confirm_exit() {
	echo -e "$yes\n$no" | confirm_cmd
}

# Pass variables to rofi dmenu
run_rofi() {
	echo -e "$shutdown\n$reboot_arch\n$reboot_windows\n$logout\n$hibernate\n$suspend\n$lock" | rofi_cmd
}

# Execute Command
run_cmd() {
	selected="$(confirm_exit)"
	if [[ "$selected" == "$yes" ]]; then
		if [[ $1 == '--shutdown' ]]; then
			systemctl --no-ask-password poweroff || notify-send -u critical "Shutdown request rejected" "Inhibitor is active" -i .local/share/icons/Tela-circle/symbolic/emblems/emblem-system-symbolic.svg
		elif [[ $1 == '--hibernate' ]]; then
            systemctl --no-ask-password hibernate || notify-send -u critical "Hibernation request rejected" "Inhibitor is active" -i .local/share/icons/Tela-circle/symbolic/emblems/emblem-system-symbolic.svg
		elif [[ $1 == '--reboot_arch' ]]; then
            efibootmgr-set-bootnext-current && systemctl --no-ask-password reboot || notify-send -u critical "Reboot request rejected" "Inhibitor is active" -i .local/share/icons/Tela-circle/symbolic/emblems/emblem-system-symbolic.svg
		elif [[ $1 == '--reboot_windows' ]]; then
            efibootmgr-set-bootnext-windows && systemctl --no-ask-password reboot || notify-send -u critical "Reboot request rejected" "Inhibitor is active" -i .local/share/icons/Tela-circle/symbolic/emblems/emblem-system-symbolic.svg
		elif [[ $1 == '--suspend' ]]; then
			systemctl --no-ask-password suspend-then-hibernate || notify-send -u critical "Sleep request rejected" "Inhibitor is active" -i .local/share/icons/tela-circle/symbolic/emblems/emblem-system-symbolic.svg
		elif [[ $1 == '--logout' ]]; then
            hyprctl dispatch exit
		elif [[ $1 == '--lock' ]]; then
            loginctl lock-session
		fi
	else
		exit 0
	fi
}

# Actions
chosen="$(run_rofi)"
case ${chosen} in
    $shutdown)
		run_cmd --shutdown
        ;;
    $hibernate)
		run_cmd --hibernate
        ;;
    $reboot_arch)
		run_cmd --reboot_arch
        ;;
    $reboot_windows)
		run_cmd --reboot_windows
        ;;
    $lock)
		run_cmd --lock
        ;;
    $suspend)
		run_cmd --suspend
        ;;
    $logout)
		run_cmd --logout
        ;;
esac
