function l --wraps=ls --description 'alias l=eza -F --git --group-directories-first'
    eza -F --git --group-directories-first $argv
end
