# Dotfiles

Shared NixOS / Ubuntu. KISS.

- NixOS-specific belongs in nixos-config; chezmoi stays portable.
- Same value in both is fine; don't add conditionals to avoid harmless duplicates.
- Gate machine-only files in `.chezmoiignore`, don't template empty files.
- Delete dead config outright.
- `private_` prefixes for strict permissions.
- Never `chezmoi apply` without reviewing dry-run first.
