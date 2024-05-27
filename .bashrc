# _                  _
#(_)______   ___   _| | __
#| |_  /\ \ / / | | | |/ /
#| |/ /  \ V /| |_| |   <
#|_/___|  \_/  \__, |_|\_\
#              |___/
#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return
printf '\x0a\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x0a\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\x20\u2588\u2588\x20\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\x20\u2588\u2588\x20\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\x20\u2588\u2588\x20\x0a\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x0a\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\x20\x20\x20\x20\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\x20\x20\x20\x20\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\x20\x20\x20\x20\x0a\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x20\x20\u2588\u2588\x0a\x0a'

PS1='\u@\h \W \$ '

export LANG=en_US.UTF-8
export EDITOR='nvim'

# Aliases
alias mc='mc -S modarin256root-defbg --nosubshell' #mc skin
alias ls='eza'
alias ll='eza -l'
alias la='eza -la'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias config='/usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME'

