# If not running interactively, don't do anything
[[ $- != *i* ]] && return

echo '
  ██  ██  ██  ██  ██  ██  ██  ██  ██
 ████████ ██ ████████ ██ ████████ ██
  ██  ██  ██  ██  ██  ██  ██  ██  ██
 ████████    ████████    ████████
  ██  ██  ██  ██  ██  ██  ██  ██  ██
'

PS1='\u@\h \W \$ '
# PS1="\u@\h \w -> "

export EDITOR='nvim'

# Aliases
alias ls='eza'
alias ll='eza -l'
alias la='eza -la'
alias config='/usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME'
alias cat='bat --theme=1337'
alias ruman='LANG=ru_RU.UTF-8 man'

shopt -s autocd
shopt -s cdable_vars
shopt -s cdspell
shopt -s dirspell
shopt -s nocaseglob
shopt -s globstar


# run() { 
#     clang++ $@ -o .clang-compiled-0000 &&
#     ./.clang-compiled-0000 &&
#     rm .clang-compiled-0000
# }

eval "$(zoxide init --hook pwd --cmd cd bash)"

export GPG_TTY="$(tty)"

# Manpages with bat
if $(which bat >/dev/null 2>&1); then
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
    export MANROFFOPT='-c' # Fix escape sequences in bat
    # export MANPAGER="sh -c \"sed -e 's/\x1b\[[0-9;]*m//g' | bat -l man -p\"" # Aternative fix
fi
