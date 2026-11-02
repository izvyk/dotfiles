# Shell assistant: describe a command in plain words, press Alt+E, and the
# line becomes the command; review it, then Enter. Replaces fish's Alt+E
# (edit the line in $EDITOR), which Alt+V still does.
status is-interactive; and type -q aichat; or return

function _aichat_fish
    set -l _old (commandline)
    if test -n "$_old"
        echo -n "⌛"
        commandline -f repaint
        # aichat writes for $SHELL, the login shell, which needn't be fish.
        commandline (AICHAT_SHELL=fish aichat -e $_old)
    end
end
bind \ee _aichat_fish
