if status is-interactive
    # Greeting in top-level and ns shells, where it separates them in the
    # scrollback. Not in yazi's ! shell or in Zed's terminal.
    set fish_greeting
    if set -q NIX_SHELL_DEPTH; or begin
            not set -q YAZI_LEVEL; and not set -q ZED_TERM
        end
        set fish_greeting '
  ██  ██  ██  ██  ██  ██  ██  ██  ██
 ████████ ██ ████████ ██ ████████ ██
  ██  ██  ██  ██  ██  ██  ██  ██  ██
 ████████    ████████    ████████
  ██  ██  ██  ██  ██  ██  ██  ██  ██
'
    end

    # fish's default theme uses the terminal's named colours, so it follows the
    # shared theme. Only change: commands in blue.
    set -g fish_color_command blue

    type -q zoxide; and zoxide init --hook pwd --cmd cd fish | source

    bind \em __fish_man_page          # Alt + M = manpage
    bind \el nextd-or-forward-word    # Alt + L = next visited directory
    bind \eh prevd-or-backward-word   # Alt + H = previous visited directory

    umask 077
    # Appended to $PATH itself (fish_user_paths always go first), and moved
    # there if inherited: user-writable dirs mustn't shadow system binaries.
    fish_add_path -P -a -m ~/.local/bin ~/go/bin
end
