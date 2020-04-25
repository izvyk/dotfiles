#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '

export LANG=en_US.UTF-8
export EDITOR='nvim'

# Aliaces
alias mc='mc -S modarin256root-defbg --nosubshell' #mc skin
alias ls='lsd' #ls defuxe instead of usual ls
alias ll='lsd -lA' #ls defuxe instead of usual ls
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias config='/usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME'

