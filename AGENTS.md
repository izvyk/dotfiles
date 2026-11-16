# Dotfiles

Shared by two machines. KISS.

- malvina: work laptop, Ubuntu. buratino: private laptop, NixOS.
- OS differences: `.chezmoi.osRelease.id`. Machine differences (git identity, ssh
  hosts): `.chezmoi.hostname`, testing for malvina, with buratino as the else.
- NixOS-specific belongs in nixos-config; chezmoi stays portable.
- A value that's the same on both machines is fine; don't add machine conditionals
  to avoid it. Across files, stay DRY: shared values go in `.chezmoidata/`.
- Colours come only from `.chezmoidata/theme.toml`; app configs are templates that
  read it, never hex literals. Switching theme = editing that one file.
- Gate machine-only files in `.chezmoiignore`, don't template empty files.
- Delete dead config outright. `.archive/` keeps the few retired files that were
  never committed; chezmoi doesn't deploy it.
- No one-off cleanup in the repo: no `.chezmoiremove`, no run_once migration
  scripts. Delete stale targets by hand on each machine.
- `private_` prefixes for strict permissions.
- Never `chezmoi apply` without reviewing dry-run first.
- This repo is public. Anything private goes in an `encrypted_` file; `~/.ssh/config`
  is an encrypted template, change it with `chezmoi edit ~/.ssh/config`. A single
  secret inside an otherwise public config goes in `.secrets/<name>.age`
  (`chezmoi encrypt`), read with `include ".secrets/<name>.age" | decrypt`, and
  is skipped when `~/.config/chezmoi/key.txt` is missing.
- ssh: FIDO keys on the YubiKey, named per host in `~/.ssh/config`, and the session's
  default agent.
