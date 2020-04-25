# _                  _
#(_)______   ___   _| | __
#| |_  /\ \ / / | | | |/ /
#| |/ /  \ V /| |_| |   <
#|_/___|  \_/  \__, |_|\_\
#              |___/
#
# ~/.zshrc
#

export TERM="xterm-256color"

# Path to your oh-my-zsh installation.
export ZSH="/home/izvyk/.oh-my-zsh"

# ANTIGEN
source /home/izvyk/.antigen.zsh

# Load the oh-my-zsh's library.
antigen use oh-my-zsh

antigen bundle git
antigen bundle zsh-autosuggestions
antigen bundle ast-syntax-highlighting
antigen bundle sh-autopair
antigen bundle sh-completions

antigen bundle hlissner/zsh-autopair
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zdharma/fast-syntax-highlighting
antigen bundle zsh-users/zsh-completions


# Tell Antigen that you're done.
antigen apply




# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

#See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
export UPDATE_ZSH_DAYS=7

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
#COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
	git 
	zsh-autosuggestions
	fast-syntax-highlighting
	zsh-autopair
	zsh-completions
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8
export EDITOR='nvim'

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

#Aliases
alias mc='mc -S modarin256root-defbg --nosubshell' #mc skin
alias ls='lsd' #ls defuxe instead of usual ls
alias ll='lsd -lA' #ls defuxe instead of usual ls
#alias lcd='cd $1 && lsd'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias config='/usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME'

POWERLEVEL9K_MODE='nerdfond-complete'
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
	#custom_arch_icon
	virtualenv
	dir
	root_indicator
	vcs
) #сегменты слева

POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
	status
	command_execution_time
	user
	vi_mode
	time
	battery
)

POWERLEVEL9K_CUSTOM_ARCH_ICON="echo " #$'\uF303'
POWERLEVEL9K_CUSTOM_ARCH_ICON_BACKGROUND='238'
POWERLEVEL9K_CUSTOM_ARCH_ICON_FOREGROUND='039' #'015'

# user
POWERLEVEL9K_USER_DEFAULT_FOREGROUND='208'
POWERLEVEL9K_USER_SUDO_FOREGROUND='160'
POWERLEVEL9K_USER_ROOT_BACKGROUND='160'
POWERLEVEL9K_USER_ROOT_FOREGROUND='238'

#POWERLEVEL9K_USER_BACKGROUND='208'

# battery
POWERLEVEL9K_BATTERY_LOW_BACKGROUND='238'
POWERLEVEL9K_BATTERY_LOW_FOREGROUND='009'
POWERLEVEL9K_BATTERY_CHARGING_BACKGROUND='238'
POWERLEVEL9K_BATTERY_CHARGING_FOREGROUND='076'
POWERLEVEL9K_BATTERY_CHARGED_BACKGROUND='238'
POWERLEVEL9K_BATTERY_CHARGED_FOREGROUND='076'
POWERLEVEL9K_BATTERY_DISCONNECTED_BACKGROUND='238'
POWERLEVEL9K_BATTERY_DISCONNECTED_FOREGROUND='250'
POWERLEVEL9K_BATTERY_LOW_THRESHOLD=15
POWERLEVEL9K_BATTERY_VERBOSE=false
POWERLEVEL9K_BATTERY_STAGES=''
POWERLEVEL9K_RIGHT_SUBSEGMENT_SEPARATOR_COLOR='208'

#POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=''
#POWERLEVEL9K_BATTERY_ICON='\uf1e6 '

POWERLEVEL9K_VI_INSERT_MODE_STRING='' #hide insert mode message
#Plugged icon 2690 F1E6
#Arch icon 2928 F303


POWERLEVEL9K_STATUS_OK_BACKGROUND='000'               #alpha
POWERLEVEL9K_STATUS_OK_FOREGROUND='040'               #green
POWERLEVEL9K_STATUS_ERROR_BACKGROUND='160'            #red
POWERLEVEL9K_STATUS_ERROR_FOREGROUND='226'            #yellow


POWERLEVEL9K_DIR_DEFAULT_BACKGROUND='039'             #blue
POWERLEVEL9K_DIR_DEFAULT_FOREGROUND='000'             #alpha
POWERLEVEL9K_DIR_HOME_BACKGROUND='039'                #blue
POWERLEVEL9K_DIR_HOME_FOREGROUND='000'                #alpha
POWERLEVEL9K_DIR_HOME_SUBFOLDER_BACKGROUND='039'      #blue
POWERLEVEL9K_DIR_HOME_SUBFOLDER_FOREGROUND='000'      #alpha
POWERLEVEL9K_DIR_WRITABLE_FORBIDDEN_BACKGROUND='160'  #red
POWERLEVEL9K_DIR_WRITABLE_FORBIDDEN_FOREGROUND='226'  #yellow

POWERLEVEL9K_LEFT_SUBSEGMENT_SEPARATOR=$'\uE0B1' # 
POWERLEVEL9K_HOME_ICON=$'\uF015'                  # 
POWERLEVEL9K_HOME_SUB_ICON=$'\uF07C'              # 

POWERLEVEL9K_TIME_BACKGROUND='238'
POWERLEVEL9K_TIME_FOREGROUND='208'

#POVERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=10

#POWERLEVEL9K_TIME_BACKGROUND

VIRTUAL_ENV_DISABLE_PROMPT=1
