function la --wraps=ls --wraps='eza -la --git --group-directories-first' --description 'alias la=eza -la --git --group-directories-first'
    eza -la --git --group-directories-first $argv
end
