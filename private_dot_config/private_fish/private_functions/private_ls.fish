function ls --wraps='eza --git --group-directories-first' --description 'alias ls=eza --git --group-directories-first'
    eza --git --group-directories-first $argv
end
