# Dotfiles conventions

Shared between NixOS (`buratino`, `tortila`) and Ubuntu. KISS: prefer no
conditional over a clever conditional.

## Layering

- NixOS owns in `nixos-config`: fonts (`fonts.fontconfig`), `EDITOR`
  (`programs.neovim.defaultEditor`), Qt platform, cursor, `QT_QPA_PLATFORM`.
- Chezmoi owns the portable remainder, identical content on all machines.
- Same value declared in both systems is fine (defense in depth, no
  conditionals). Reaching for `{{if}}` to avoid a harmless same-value file
  is over-engineering.

## Machine-specific files

- Prefer `.chezmoiignore` gating over in-file `{{if}}` wrappers. Templating
  a file renders an *empty* file on excluded machines; ignoring means *no*
  file — almost always what you want.
- `.chezmoiignore` is itself a template: use
  `{{ if eq .chezmoi.osRelease.id "nixos" }}` / `{{ else }}` branches.
- See `fish/functions/conf.fish` + `fontconfig` for the canonical pattern.

## Hygiene

- Delete dead config outright (Hyprland-era flags, upstream defaults like
  `MOZ_ENABLE_WAYLAND`, bogus entries like unexpanded `${...}` in
  `environment.d`). Don't gate what nothing reads.
- Strict permissions: `private_` source prefixes so targets render
  `0600`/`0700`. Verify with `chezmoi diff --no-pager`.
- Keep `izvyk` identifiers in `xkb/symbols` untouched; only the `custom`
  laptop selector is templated per-machine.

## Validation

- `chezmoi cat <target> | fish --no-execute` for fish functions.
- `chezmoi ignored` (+ `--override-data` simulating the other OS) to verify
  gating both ways.
- `git diff --check`; never `chezmoi apply` without reviewing dry-run first.
