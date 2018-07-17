"===========================================================
" NeoVim config
" Author: Rich Grundy
"
" Borrowed bits from: martin-svk/dot-files.
"===========================================================

"===========================================================
" Plugin Setup {{{
"===========================================================
" Autoinstall vim-plug {{{
if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
        \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  augroup plug_install
    autocmd VimEnter * PlugInstall
  augroup END
endif
"}}}
call plug#begin('~/.config/nvim/plugged')

" Generic plugins {{{

" Async syntax checking
Plug 'w0rp/ale'
" Autocomplete
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
" commenting stuff
Plug 'tpope/vim-commentary'
" Snippets!!
Plug 'SirVer/ultisnips'
" Polyglot - all the languages!
Plug 'sheerun/vim-polyglot'
" }}}

" Text manipulation plugins {{{
Plug 'tpope/vim-surround'
" }}}

" External command plugins {{{
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'tpope/vim-fugitive'
" }}}

" Ruby/Rails plugins {{{
Plug 'tpope/vim-rails', { 'for': ['ruby', 'eruby', 'haml', 'coffee'] }
Plug 'tpope/vim-bundler', { 'for': ['ruby', 'eruby', 'haml'] }
" }}}

" JS/ES6 Plugins {{{
Plug 'carlitux/deoplete-ternjs', { 'do': 'npm install -g tern' }
" }}}

" Themes plugins {{{
Plug 'jpo/vim-railscasts-theme'
Plug 'chriskempson/base16-vim'
" }}}

" Elixir {{{
"Plug 'slashmili/alchemist.vim'
" }}}

" Golang {{{
Plug 'fatih/vim-go'
Plug 'zchee/deoplete-go', { 'do': 'make'}
" }}}

call plug#end()


"}}}

"===========================================================
" Plugin settings {{{
"===========================================================
" Deoplete settings {{{
let g:deoplete#enable_at_startup=1
"}}}

" UltiSnips settings {{{
let g:UltiSnipsUsePythonVersion=3
"}}}

" FZF {{{
" let $FZF_DEFAULT_OPTS='--reverse'
" let $FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow --glob "!.git/*"'
" }}}

" Vim-go settings {{{
let g:go_highlight_build_constraints = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_operators = 1
let g:go_highlight_structs = 1
let g:go_highlight_types = 1
" }}}

" Ale settings {{{
let g:ale_sign_error = '⤫'
let g:ale_sign_warning = '⚠'
" }}}
"}}}

"===========================================================
" Basic settings {{{
"===========================================================
set autoindent
syntax on
filetype plugin indent on

set number
set relativenumber
set showmode
set modeline
set modelines=3
set history=500
set pastetoggle=<F2>
set lazyredraw
set noswapfile
set clipboard^=unnamed
set colorcolumn=80

set completeopt-=preview

" Search settings {{{
set hlsearch
set incsearch
set ignorecase
set smartcase
"}}}

" Tab settings {{{
set softtabstop=2
set shiftwidth=2
set expandtab
" }}}

" Wildmenu settings {{{
set wildmenu
set wildmode=list:longest,list:full
set wildignore+=*.o,*.obj,.git,*.class
" }}}

" Special character settings {{{
set list
set listchars=tab:▸\ ,eol:¬
" }}}

" Spelling settings {{{
set nospell " Enabled via toggle <F4>.
set spelllang=en_gb
" }}}

" Fold settings {{{
"
set foldmethod=marker
set foldlevel=2
"}}}

"}}}

"===========================================================
" Theme setup {{{
"===========================================================
let base16colorspace=256

function! MyHighlights() abort
  highlight Normal ctermbg=NONE guibg=NONE ctermfg=255
  highlight TabLineFill term=bold cterm=bold ctermfg=255 ctermbg=0
  highlight CursorColumn term=underline cterm=underline guibg=#333435
  highlight NonText ctermbg=NONE ctermfg=235 guifg=#424242 gui=NONE
  highlight SpecialKey ctermbg=NONE ctermfg=235 guifg=#424242 gui=NONE
  highlight ColorColumn ctermbg=233 guibg=#464646
  highlight link TrailingWhiteSpace Search
endfunction

augroup Colours
    autocmd!
    autocmd ColorScheme * call MyHighlights()
augroup END

colorscheme railscasts
" colorscheme base16-railscasts
"}}}

"===========================================================
" Auto commands {{{
"===========================================================
augroup MyStandardAu
  autocmd!

  " Don't insert comment lead character when pressing o.
  autocmd FileType * set formatoptions-=o

  " Highlighting trailing whitespace.
  autocmd BufWinEnter * let w:twsm=matchadd('TrailingWhiteSpace', '\s\+$')
augroup END


" PHP commands {{{
augroup PHPAu
  autocmd!
  autocmd FileType php setlocal softtabstop=4 shiftwidth=4
augroup END
" }}}

" Python commands {{{
augroup PythonAu
  autocmd!
  autocmd FileType python setlocal softtabstop=4 shiftwidth=4
augroup END
" }}}

" Golang commands {{{
augroup GolangAu
  autocmd!
  autocmd FileType go  setlocal noexpandtab shiftwidth=4 softtabstop=4 tabstop=4
augroup END
" }}}

"}}}

"===========================================================
" Mappings {{{
"===========================================================
" Trying spacebar as leader (while still allowing normal leadermap)
map <space> <leader>

nnoremap <leader>ew :e <C-R>=expand("%:p:h") . "/" <CR>
nnoremap <leader>es :sp <C-R>=expand("%:p:h") . "/" <CR>
nnoremap <leader>ev :vsp <C-R>=expand("%:p:h") . "/" <CR>
nnoremap <leader>et :tabe <C-R>=expand("%:p:h") . "/" <CR>

" Remove trailing whitespace with :RMTWS
:command! -range=% RMTWS let b:wv = winsaveview() |
      \ execute 'keeppattern ' . <line1> . ',' . <line2> . 's/\s\+$//' |
      \ call winrestview(b:wv)
nnoremap <leader>rw <esc>:RMTWS<CR>
" Spell toggle
nnoremap <silent> <F4> :set spell!<CR> :set spell?<CR>
" Clear search highlight
nnoremap <Leader>ssc :nohls<CR>
" For when you forget to sudo!
cnoremap w!! %!sudo tee > /dev/null %
" Search current word.
nnoremap <silent> S :Ag <C-R><C-W><CR>
" Quicklist.
nnoremap ]q :cnext<CR>
nnoremap [q :cprevious<CR>
"}}}

"===========================================================
" Plugin mappings {{{
"===========================================================
" FZF {{{
nnoremap <silent> <leader>o :Files<CR>
nnoremap <silent> <leader>g :GFiles<CR>
nnoremap <silent> <leader>f :GFiles?<CR>
nnoremap <silent> <leader>c :BCommits<CR>
nnoremap <silent> <leader>s :Snippets<CR>
nnoremap <silent> <leader>b :Buffers<CR>
nnoremap <silent> <leader>a :Ag
" }}}

" Deoplete {{{
" Insert <TAB> or select next match
inoremap <silent> <expr> <Tab> utils#tabComplete()
inoremap <silent> <expr> <C-]> utils#manualTagComplete()
"}}}
" }}}
