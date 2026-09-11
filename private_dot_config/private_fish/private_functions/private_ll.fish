function ll --wraps=ls --wraps='eza --color-scale -l --git --git-ignore --group-directories-first --time-style iso' --description 'alias ll=eza --color-scale -l --git --git-ignore --group-directories-first --time-style iso'
  eza --color-scale -l --git --git-ignore --group-directories-first --time-style iso $argv;
end
