filetype plugin indent on "Определение типа файла
set encoding=utf-8
set nocompatible "Отключает обратную совместимость с Vi


"
let g:python3_host_prog = '/usr/bin/python3'



" <Plugins>
call plug#begin('~/.config/nvim/plugged')
    Plug 'neovim/nvim-lspconfig'
    Plug 'hrsh7th/nvim-cmp'
    Plug 'hrsh7th/cmp-nvim-lsp'

	Plug 'sainnhe/gruvbox-material'
	Plug 'vim-airline/vim-airline'
    Plug 'ryanoasis/vim-devicons'
	"Plug 'vim-airline/vim-airline-themes'
call plug#end()
" </Plugins>


" <Keybindings>
inoremap jk <esc>
nnoremap ,<space> :nohlsearch<CR> "Выключить подсветку найденного
" </Keybindings>


"Табы
set tabstop=4
set shiftwidth=4
set softtabstop=4 " 4 пробела в табе
set expandtab " Ставить пробелы вместо табов

set smarttab
set autoindent " Автоотступы


set mouse=a
set scrolloff=5
set number " Номера строк
syntax on " Подсветка синтаксиса
set colorcolumn=79 " выделение 79 символа в каждой строке
set wrap linebreak nolist "Перенос строк по словам
set cursorline " Выделение строки с курсором

let &t_SI.="\e[5 q" "SI = режим вставки
let &t_SR.="\e[3 q" "SR = режим замены
let &t_EI.="\e[1 q" "EI = нормальный режим
"Где 1 - это мигающий прямоугольник
"2 - обычный прямоугольник
"3 - мигающее подчёркивание
"4 - просто подчёркивание
"5 - мигающая вертикальная черта
"6 - просто вертикальная черта

"set hidden
"set vb
"set nowritebackup
set noswapfile
set nobackup
"set splitbelow
"set splitright
set ignorecase




" <Color scheme>
	let $NVIM_TUI_ENABLE_TRUE_COLOR=1

	" Поддержка цветов
	if has('termguicolors')
	  set termguicolors
	endif

	set background=dark

	" available values: 'hard', 'medium'(default), 'soft'
	let g:gruvbox_material_background = 'medium'
	let g:gruvbox_material_transparent_background = 1
	colorscheme gruvbox-material
	let g:airline_theme = 'gruvbox_material'
	"let g:airline#extensions#tabline#enabled = 1
" </Color scheme>

" <Airline>
    let g:airline_powerline_fonts = 1
    let g:Powerline_symbols='unicode'
" </Airline>


" <LSP server settings>
lua << EOF
  local nvim_lsp = require('lspconfig')

  -- Use an on_attach function to only map the following keys
  -- after the language server attaches to the current buffer
  local on_attach = function(client, bufnr)

    local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
    local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

    -- Enable completion triggered by <c-x><c-o>
    buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- Mappings.
    local opts = { noremap=true, silent=true }

    -- See `:help vim.lsp.*` for documentation on any of the below functions
    buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
    buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
    buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
    buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
    buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
    buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
    buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
    buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
    buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
    buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
    buf_set_keymap('n', '<space>f', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)

  end

  -- Use a loop to conveniently call 'setup' on multiple servers and
  -- map buffer local keybindings when the language server attaches
  local servers = { 'pyright' }
  for _, lsp in ipairs(servers) do
    nvim_lsp[lsp].setup {
      on_attach = on_attach,
      flags = {
        debounce_text_changes = 150,
      }
    }
  end
EOF
" </LSP server settings>
