let mapleader = " "
let maplocalleader = " "

set timeout timeoutlen=300
set nocompatible
set tabstop=2 shiftwidth=2 expandtab noshiftround
set scrolloff=5
set updatetime=100
set signcolumn=auto
highlight SignColumn guibg=NONE ctermbg=NONE
set relativenumber
set ruler
set showmatch
set hlsearch incsearch
set ignorecase smartcase

inoremap jj <Esc>

syntax on
filetype plugin indent on

au BufRead,BufNewFile .sdkmanrc setfiletype jproperties
au BufRead,BufNewFile .fzfrc setfiletype sh

call plug#begin()

Plug 'mtdl9/vim-log-highlighting'
Plug 'machakann/vim-highlightedyank'
Plug 'tpope/vim-commentary'
Plug 'preservim/nerdtree'
Plug 'mechatroner/rainbow_csv'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'liuchengxu/vim-which-key'
Plug 'airblade/vim-gitgutter'

call plug#end()

nnoremap <leader>h :nohlsearch<CR>

" NERDTree
let g:NERDTreeHijackNetrw=0
let g:NERDTreeShowHidden=1
nnoremap <leader>n :NERDTreeFocus<CR>
nnoremap <C-n> :NERDTree<CR>
nnoremap <C-t> :NERDTreeToggle<CR>
nnoremap <C-f> :NERDTreeFind<CR>

" FZF
nnoremap <leader>r :Rg<CR>
nnoremap <C-p> :Files<CR>
nnoremap <C-b> :Buffers<CR>

" GitGutter
nnoremap <leader>gp :GitGutterPreviewHunk<CR>
nnoremap <leader>gs :GitGutterStageHunk<CR>
nnoremap <leader>gu :GitGutterUndoHunk<CR>
nnoremap <leader>gn :GitGutterNextHunk<CR>
nnoremap <leader>gP :GitGutterPrevHunk<CR>

" which-key
let g:which_key_map = {}
let g:which_key_map['?'] = 'show keybindings'
let g:which_key_map.h = 'clear search highlight'
let g:which_key_map.n = 'NERDTree focus'
let g:which_key_map.r = 'ripgrep'
let g:which_key_map.g = {
      \ 'name': '+git',
      \ 'p': 'preview hunk',
      \ 's': 'stage hunk',
      \ 'u': 'undo hunk',
      \ 'n': 'next hunk',
      \ 'P': 'prev hunk',
      \ }
let g:which_key_map['+'] = {
      \ 'name': '+ctrl bindings',
      \ 'n': '<C-n> NERDTree open',
      \ 't': '<C-t> NERDTree toggle',
      \ 'f': '<C-f> NERDTree find file',
      \ 'p': '<C-p> FZF files',
      \ 'b': '<C-b> FZF buffers',
      \ }
call which_key#register('<Space>', 'g:which_key_map')
nnoremap <silent> <leader>? :<c-u>WhichKey '<Space>'<CR>

