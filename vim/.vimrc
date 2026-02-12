let mapleader = " "
let maplocalleader = " "

set notimeout
set nocompatible
set tabstop=2 shiftwidth=2 expandtab noshiftround

syntax on
filetype plugin indent on

set relativenumber
set ruler
set showmatch
set hlsearch incsearch
set ignorecase smartcase

nnoremap <leader>h :nohlsearch<CR>

call plug#begin()

Plug 'mtdl9/vim-log-highlighting'

call plug#end()
