function ll --wraps=ls --wraps='exa --color-scale -l --git --git-ignore --group-directories-first --time-style iso' --description 'alias ll=exa --color-scale -l --git --git-ignore --group-directories-first --time-style iso'
  exa --color-scale -l --git --git-ignore --group-directories-first --time-style iso $argv; 
end
