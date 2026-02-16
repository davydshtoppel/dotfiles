let mapleader = " "
let maplocalleader = " "

set notimeout
set nocompatible
set tabstop=2 shiftwidth=2 expandtab noshiftround
set scrolloff=5

syntax on
filetype plugin indent on

au BufRead,BufNewFile .sdkmanrc setfiletype jproperties

set relativenumber
set ruler
set showmatch
set hlsearch incsearch
set ignorecase smartcase

call plug#begin()

Plug 'mtdl9/vim-log-highlighting'
Plug 'machakann/vim-highlightedyank'
Plug 'tpope/vim-commentary'
Plug 'preservim/nerdtree'
Plug 'mechatroner/rainbow_csv'

call plug#end()

let g:NERDTreeHijackNetrw=0

nnoremap <leader>h :nohlsearch<CR>
nnoremap <leader>n :NERDTreeFocus<CR>
nnoremap <C-n> :NERDTree<CR>
nnoremap <C-t> :NERDTreeToggle<CR>
nnoremap <C-f> :NERDTreeFind<CR>

