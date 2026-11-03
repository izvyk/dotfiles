if status is-interactive
    set fish_greeting '
  ██  ██  ██  ██  ██  ██  ██  ██  ██
 ████████ ██ ████████ ██ ████████ ██
  ██  ██  ██  ██  ██  ██  ██  ██  ██
 ████████    ████████    ████████
  ██  ██  ██  ██  ██  ██  ██  ██  ██
'

    type -q zoxide; and zoxide init --hook pwd --cmd cd fish | source

    bind \em __fish_man_page          # Alt + M = manpage
    bind \el nextd-or-forward-word    # Alt + L = next visited directory
    bind \eh prevd-or-backward-word   # Alt + H = previous visited directory

    umask 077
    fish_add_path -g ~/.local/bin
end
