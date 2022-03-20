local o = vim.o -- Equal to :set
--local bo = vim.bo -- Equal to :setlocal
--local go = vim.go -- Equal to :setglobal
local cmd = vim.cmd


-- external programs
o.grepprg = 'rg -n ' -- Use ripgrep instead of grep

o.showmode = false
-- cmd 'filetype plugin indent on'
o.mouse = 'a' -- Enable mouse in all modes
o.clipboard = 'unnamedplus' -- Use system`s clipboard instead of vim`s buffer
o.number = true -- Show row numbers
o.scrolloff = 5 -- Cursor is always 5 lines below and above the edge of the screen
o.cursorline = true -- Highlight cursor line
o.colorcolumn = '80' -- Highlight 80th column
o.history = 3000 -- Instead of default 10000

-- Search
o.ignorecase = true -- Case-insensitive search
o.incsearch = true -- Search before 'Enter' hit
o.smartcase = true -- Search is case-insensitive only if search string is all lowercase
o.wrapscan = true -- Make search cyclic
-- --


--vim.g.gruvbox_contrast_dark = 'soft'
vim.opt.termguicolors = true
vim.o.guifont = "Iosevka:h16"
o.background = 'dark'

-- encoding
-- o.encoding = 'utf-8'
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
o.showbreak = '﬌ '--'﬋ '

o.shortmess = 'flmnrxtToOF'
--o.wildignore = {'.DS_Store','*.pyc','.git','node_modules','*.obj','*.o','*.a','__pycache__'}

-- Undo
o.undofile = true


-- tabs and spaces view
-- o.list = true
-- o.listchars
