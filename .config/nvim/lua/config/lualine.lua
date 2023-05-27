require'lualine'.setup {
    theme = 'gruvbox',
    options = {
        -- section_separators = { left = '', right = '' }, --                     
        -- section_separators = { left = ' ', right = ' ' }, --                    
        section_separators = { left = '', right = '' },
        component_separators = { left = '|', right = '|'}--{ left = '▎', right = '▎' },--
    },
    sections = {
        -- lualine_a = {'mode'},
        lualine_b = {'branch', 'diff'},
        lualine_c = {'filename'},
        lualine_x = {'diagnostics'},
        lualine_y = {'encoding', 'fileformat', 'filetype'},
        lualine_z = {'location', 'progress'},
    },
}
