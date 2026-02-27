require'nvim-treesitter.configs'.setup {
    -- Modules and its options go here
    highlight = {
        enable = true,
        disable = { 'cpp', 'lua', 'tex' }
    },
    incremental_selection = { enable = true },
    textobjects = { enable = true },
}
