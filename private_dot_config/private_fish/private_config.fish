if status is-interactive
    set fish_greeting '
  ██  ██  ██  ██  ██  ██  ██  ██  ██
 ████████ ██ ████████ ██ ████████ ██
  ██  ██  ██  ██  ██  ██  ██  ██  ██
 ████████    ████████    ████████
  ██  ██  ██  ██  ██  ██  ██  ██  ██
'

    # Use yubikey-agent where it runs; elsewhere keep the session's agent.
    set -l yubikey_sock $XDG_RUNTIME_DIR/yubikey-agent/yubikey-agent.sock
    test -S $yubikey_sock; and set -gx SSH_AUTH_SOCK $yubikey_sock

    type -q zoxide; and zoxide init --hook pwd --cmd cd fish | source

    bind \em __fish_man_page          # Alt + M = manpage
    bind \el nextd-or-forward-word    # Alt + L = next visited directory
    bind \eh prevd-or-backward-word   # Alt + H = previous visited directory

    umask 077
    fish_add_path -g ~/.local/bin
end
