if status is-interactive
    # Commands to run in interactive sessions can go here

    set fish_greeting '
 ██  ██  ██  ██  ██  ██  ██  ██  ██
████████ ██ ████████ ██ ████████ ██
 ██  ██  ██  ██  ██  ██  ██  ██  ██
████████    ████████    ████████
 ██  ██  ██  ██  ██  ██  ██  ██  ██
' 
    # printf '\x0a\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x0a\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\x20\u2588\u2588\x20\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\x20\u2588\u2588\x20\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\x20\u2588\u2588\x20\x0a\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x0a\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\x20\x20\x20\x20\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\x20\x20\x20\x20\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\x20\x20\x20\x20\x0a\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x0a\x0a'
    
    fish_ssh_agent
    set -x GPG_TTY $(tty)
    set -x MANPAGER "bat -l man -p"

    zoxide init --hook pwd --cmd cd fish | source

end

