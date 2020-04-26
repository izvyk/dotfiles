syntax on

"set hidden
"set tabstop=2
"set shiftwidth=2
"set softtabstop=2
"set expandtab
"set vb
set number
set encoding=utf8
"set nowritebackup
set noswapfile
set nobackup
"set splitbelow
"set splitright
set ignorecase


call plug#begin('~/.config/nvim/plugged')
Plug 'sainnhe/gruvbox-material'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
call plug#end()

" <Color scheme>
let $NVIM_TUI_ENABLE_TRUE_COLOR=1

" important!
if has('termguicolors')
  set termguicolors
endif

" for dark version
set background=dark

" available values: 'hard', 'medium'(default), 'soft'
let g:gruvbox_material_background = 'medium'
let g:gruvbox_material_transparent_background = 1
colorscheme gruvbox-material
let g:airline_theme = 'gruvbox_material'
"let g:airline#extensions#tabline#enabled = 1
" </Color scheme>

