local status_ok, telescope = pcall(require, 'telescope' )
if not status_ok then
    vim.api.nvim_err_writeln('telescope not found')
    return
end

local status_ok, telescope = pcall(require, 'telescope')
if not status_ok then
    return
end

telescope.setup {}

telescope.load_extension('fzf')
