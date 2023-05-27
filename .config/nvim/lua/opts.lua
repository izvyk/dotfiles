local o = vim.o -- Equal to :set
local g = vim.g
--local bo = vim.bo -- Equal to :setlocal
--local go = vim.go -- Equal to :setglobal
local cmd = vim.cmd

-- external programs
if (vim.fn.systemlist('which grep')[1]) then
    o.grepprg = 'rg -n ' -- Use ripgrep instead of grep
end

o.showmode = false
-- cmd 'filetype plugin indent on'
o.mouse = 'a' -- Enable mouse in all modes
o.number = true -- Show row numbers
o.relativenumber = true
o.scrolloff = 5 -- Cursor is always 5 lines below and above the edge of the screen
o.cursorline = true -- Highlight cursor line
o.colorcolumn = '80' -- Highlight 80th column
o.history = 3000 -- Instead of default 10000
laststatus = 3 -- global statusline

-- Search
o.ignorecase = true -- Case-insensitive search
o.incsearch = true -- Search before 'Enter' hit
o.smartcase = true -- Search case-sensitive if uppercase exists
o.wrapscan = true -- Make search cyclic

vim.opt.termguicolors = true
vim.o.guifont = 'Iosevka:h16, Hack:h16'

-- encoding
o.fileencodings = 'utf-8,cp1251,koi8-r,cp866'

-- tabs
o.tabstop = 4
o.shiftwidth = o.tabstop
o.softtabstop = o.tabstop
o.expandtab = true -- Replace tabs with whitespaces
o.smarttab = true
o.autoindent = true
o.smartindent = true

-- linebreaks
o.linebreak = true
o.breakindent = true
o.showbreak = '﬌ ' --'﬋ '

o.shortmess = 'flmnrxtToOF'

-- [empty] tabs and spaces view
-- o.list = true
-- o.listchars

-- TODO: keyboard layouts
-- cmd 'setlocal spell spelllang=ru_yo,en_us'
-- o.keymap = 'russian-jcukenwin'
-- o.iminsert = 0
-- o.imsearch = 0

-- clipboard
o.clipboard = 'unnamedplus' -- Use system`s clipboard instead of vim`s buffer
if (vim.fn.systemlist 'uname -a'[1]:find'icrosoft') then -- WSL clipboard fix
    vim.g.clipboard = {
        name = 'WslClipboard',
        copy = {
            ['+'] = 'clip.exe',
            ['*'] = 'clip.exe',
        },
        paste = {
            ['+'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
            ['*'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
        },
        cache_enabled = 0,
    }
end
