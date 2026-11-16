#!/usr/bin/sh

# lock_non_private_screenshot_cmd="hyprlock -c /home/$USER/.config/hypr/hyprlock-non-private.conf"; lock_non_private_wallpaper_cmd="hyprlock -c /home/$USER/.config/hypr/hyprlock-non-private-background-wallpaper.conf"; lock_private_cmd="hyprlock --immediate -c /home/$USER/.config/hypr/hyprlock-private.conf"; gracefile="/home/$USER/.cache/lock-with-grace"; hyprland_dpms_status="$$(hyprctl monitors -j | gojq -r "all(.dpmsStatus == true)")" ; if $$(/home/$USER/.local/bin/lock-is-private.sh); then $$lock_private_cmd; elif [ -f "$$gracefile" ]; then rm $$gracefile; [ "$$hyprland_dpms_status" == "true" ] &&  $$lock_non_private_screenshot_cmd || $$lock_non_private_wallpaper_cmd; else [ "$$hyprland_dpms_status" == "true" ] && $$lock_non_private_screenshot_cmd --immediate || $$lock_non_private_wallpaper_cmd --immediate; fi

# lock_non_private_screenshot_cmd="hyprlock -c /home/$USER/.config/hypr/hyprlock-non-private.conf"
# lock_non_private_wallpaper_cmd="hyprlock -c /home/$USER/.config/hypr/hyprlock-non-private-background-wallpaper.conf"
# lock_private_cmd="hyprlock --immediate -c /home/$USER/.config/hypr/hyprlock-private.conf"
# gracefile="/home/$USER/.cache/lock-with-grace"
# hyprland_dpms_status="$(hyprctl monitors -j | gojq -r 'all(.dpmsStatus == true)')"
#
# if $(/home/$USER/.local/bin/lock-is-private.sh); then
#     $lock_private_cmd
# elif [ -f "$gracefile" ]; then
#     rm $gracefile
#
#     [ "$hyprland_dpms_status" == "true" ] &&
#         $lock_non_private_screenshot_cmd ||
#         $lock_non_private_wallpaper_cmd
# else
#     [ "$hyprland_dpms_status" == "true" ] &&
#         $lock_non_private_screenshot_cmd --immediate ||
#         $lock_non_private_wallpaper_cmd --immediate
# fi
