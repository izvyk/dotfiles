# Shell assistant. `ii` expands to `aichat`. Alt+E runs `aichat -e` on what's
# typed (plain words), with its execute/revise/describe/copy menu. Replaces
# fish's Alt+E (edit the line in $EDITOR), which Alt+V still does.
status is-interactive; and type -q aichat; or return

abbr -a ii aichat

function _aichat_fish
    set -l line (commandline)
    test -n "$line"; or return
    commandline -r -- "aichat -e "(string escape -- "$line")
    commandline -f execute
end
bind \ee _aichat_fish
