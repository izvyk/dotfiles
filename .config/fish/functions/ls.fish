function ls --wraps='exa --git --git-ignore --group-directories-first' --description 'alias ls=exa --git --git-ignore --group-directories-first'
  exa --git --git-ignore --group-directories-first $argv; 
end
