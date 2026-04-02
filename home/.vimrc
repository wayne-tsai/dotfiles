" ── General ───────────────────────────────────────────────────────────────────
set nocompatible
set encoding=utf-8
set fileencoding=utf-8
set history=1000
set undolevels=1000
set autoread
set hidden
set backspace=indent,eol,start
set noerrorbells
set visualbell t_vb=

" ── UI ────────────────────────────────────────────────────────────────────────
set number
set relativenumber
set cursorline
set showcmd
set showmode
set ruler
set laststatus=2
set wildmenu
set wildmode=list:longest,full
set wildignore=*.o,*.pyc,*.swp,*.class,node_modules/**
set scrolloff=5
set sidescrolloff=10
set splitbelow
set splitright
set lazyredraw

" ── Colors ────────────────────────────────────────────────────────────────────
syntax enable
set t_Co=256
set background=dark
try
    colorscheme desert
catch
endtry

" ── Search ────────────────────────────────────────────────────────────────────
set incsearch
set hlsearch
set ignorecase
set smartcase
nnoremap <silent> <Esc><Esc> :nohlsearch<CR>

" ── Indentation ───────────────────────────────────────────────────────────────
set autoindent
set smartindent
set expandtab
set tabstop=4
set softtabstop=4
set shiftwidth=4
set shiftround

" ── Files & Backups ───────────────────────────────────────────────────────────
set noswapfile
set nobackup
set nowritebackup
if has('persistent_undo')
    set undofile
    set undodir=~/.vim/undo//
    silent! call mkdir(expand(&undodir), 'p')
endif

" ── Clipboard ─────────────────────────────────────────────────────────────────
if has('clipboard')
    set clipboard=unnamedplus
endif

" ── Key mappings ──────────────────────────────────────────────────────────────
let mapleader = " "

" Fast save / quit
nnoremap <Leader>w :w<CR>
nnoremap <Leader>q :q<CR>
nnoremap <Leader>Q :qa!<CR>

" Split navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Move lines up/down
nnoremap <A-j> :m .+1<CR>==
nnoremap <A-k> :m .-2<CR>==
vnoremap <A-j> :m '>+1<CR>gv=gv
vnoremap <A-k> :m '<-2<CR>gv=gv

" Better indenting in visual mode
vnoremap < <gv
vnoremap > >gv

" Yank to end of line (consistent with D, C)
nnoremap Y y$

" Keep cursor centred on search navigation
nnoremap n nzzzv
nnoremap N Nzzzv

" ── Status line ───────────────────────────────────────────────────────────────
set statusline=%f\ %m%r%h%w\ [%Y]\ [%{&ff}]%=%l/%L\ (%p%%)\ col\ %c

" ── Filetype-specific ─────────────────────────────────────────────────────────
filetype plugin indent on
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType json setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType markdown setlocal wrap linebreak
autocmd BufWritePre * :%s/\s\+$//e   " strip trailing whitespace on save
