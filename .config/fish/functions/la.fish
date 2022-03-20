function la --wraps=ls --wraps='exa --color-scale -la --git --group-directories-first --time-style iso' --wraps='exa --color-scale -lag --git --group-directories-first --time-style iso' --description 'alias la=exa --color-scale -lag --git --group-directories-first --time-style iso'
  exa --color-scale -lag --git --group-directories-first --time-style iso $argv; 
end
