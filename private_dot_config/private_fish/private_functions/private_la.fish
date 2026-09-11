function la --wraps=ls --wraps='eza --color-scale -la --git --group-directories-first --time-style iso' --description 'alias la=eza --color-scale -la --git --group-directories-first --time-style iso'
  eza --color-scale -la --git --group-directories-first --time-style iso $argv;
end
