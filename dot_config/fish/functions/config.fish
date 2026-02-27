# Defined in - @ line 1
function config --wraps='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME' --description 'Alias to easily manage dotfiles'
  /usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $argv;
end
