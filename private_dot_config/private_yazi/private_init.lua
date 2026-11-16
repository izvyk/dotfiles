-- Plugins pinned in package.toml, keys in keymap.toml.

-- Git status signs in the file list (fetchers in yazi.toml).
require("git"):setup({})

-- Saved mounts are state, not config: keep them out of ~/.config.
-- Passwords aren't saved anywhere (no password_vault).
local state = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/yazi"
require("gvfs"):setup({
	save_path = state .. "/gvfs.private",
	save_path_automounts = state .. "/gvfs_automounts.private",
})
