# Izvyk`s dotfiles

## Clone
```sh
git clone --bare https://github.com/izvyk/dotfiles.git ~/.dotfiles
```

## Add an alias
### fish
The following command will restore the `config` alias from this repo
  ```sh
  git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME checkout HEAD .config/fish/functions/config.fish
  ```
### bash
Add the following to `.bashrc` and reload bash config (e.g. by restarting bash)
  ```sh
  alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
  ```
