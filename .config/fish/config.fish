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

    # Manpages with bat
    if which bat >/dev/null 2>&1;
        set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"
        set -x MANROFFOPT '-c' # Fix escape sequences in bat
        # set -x MANPAGER "sh -c \"sed -e 's/\x1b\[[0-9;]*m//g' | bat -l man -p\"" # Aternative fix
    end

    zoxide init --hook pwd --cmd cd fish | source

    bind $argv \ch __fish_man_page

end

