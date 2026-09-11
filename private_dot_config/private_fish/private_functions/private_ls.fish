function ls --wraps='eza --git --git-ignore --group-directories-first' --description 'alias ls=eza --git --git-ignore --group-directories-first'
  eza --git --git-ignore --group-directories-first $argv;
end
