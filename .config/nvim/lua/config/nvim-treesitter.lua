local status_ok, treesitter = pcall(require, 'nvim-treesitter.configs')
if not status_ok then
    vim.api.nvim_err_writeln('treesitter not found')
    return
end

treesitter.setup {
    -- Modules and its options go here
    highlight = {
        enable = true,
        disable = { 'cpp', 'lua', 'tex' }
    },
    incremental_selection = { enable = true },
    textobjects = { enable = true },
  }
