# Load .envrc files on cd. On NixOS, nix-direnv comes from /etc/direnv/direnvrc.
status is-interactive; and type -q direnv; or return

direnv hook fish | source
