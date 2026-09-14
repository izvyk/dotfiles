function ll --wraps=ls --wraps='eza -l --git --group-directories-first' --description 'alias ll=eza -l --git --group-directories-first'
    eza -l --git --group-directories-first $argv
end
