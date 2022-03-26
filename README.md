# Izvyk`s dotfiles

## Clone
```sh
git clone --bare git@github.com:izvyk/dotfiles.git ~/.dotfiles
```

## Add an alias
### fish
The following command will restore the `config` alias from this repo
  ```sh
  git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME restore .config/fish/functions/config.fish
  ```
### bash
For using `config` alias add the following function to your `.bashrc` and reload bash config (e.g. by restarting bash)
  ```sh
  config() {
    /usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $@
  }
  ```
