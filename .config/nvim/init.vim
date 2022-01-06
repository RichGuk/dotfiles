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
Plug 'pbrisbin/vim-mkdir'
Plug 'Yggdroot/indentLine'

" " Async syntax checking
let g:ale_linters = {
\   'elixir': [],
\}
let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_insert_leave = 0

Plug 'w0rp/ale'
" Autocomplete
Plug 'neoclide/coc.nvim', {'branch': 'release'}
" commenting stuff
Plug 'tpope/vim-commentary'
" Polyglot - all the languages!
Plug 'sheerun/vim-polyglot', { 'tag': 'v4.17.0' }
" }}}

" Text manipulation plugins {{{
Plug 'machakann/vim-sandwich'
Plug 'mattn/emmet-vim'
Plug 'christianrondeau/vim-base64'
" }}}

" External command plugins {{{
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'tpope/vim-fugitive'
" }}}

" Ruby/Rails plugins {{{
Plug 'tpope/vim-rails', { 'for': ['ruby', 'eruby', 'haml', 'coffee'] }
Plug 'tpope/vim-bundler', { 'for': ['ruby', 'eruby', 'haml'] }
" }}}

" Themes plugins {{{
Plug 'jpo/vim-railscasts-theme'
" }}}

" Elixir {{{
"Plug 'slashmili/alchemist.vim'
Plug 'elixir-editors/vim-elixir'
" }}}

" Golang {{{
Plug 'fatih/vim-go'
" }}}

call plug#end()


"}}}

"===========================================================
" Plugin settings {{{
"===========================================================

" Polyglot {{{
let g:csv_no_conceal = 1
" Markdown
let g:vim_markdown_conceal_code_blocks = 0
let g:vim_markdown_new_list_item_indent = 0
" }}}

" "IndentLine {{
let g:indentLine_char = '¦'
let g:indentLine_first_char = '¦'
let g:indentLine_showFirstIndentLevel = 1
let g:indentLine_color_term = 240
let g:vim_json_syntax_conceal = 0
" }}

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

" Syntax {{{
let g:ruby_indent_assignment_style = 'variable'
"}}}
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
set colorcolumn=100
" See: https://github.com/neovim/neovim/issues/6403
set guicursor=

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
set background=dark

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
highlight Conceal ctermfg=245 ctermbg=none guibg=none
highlight Special ctermfg=29

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

" Markdown {{{
augroup MarkdownAu
  autocmd FileType markdown let b:indentLine_enabled=0
  autocmd FileType markdown setlocal colorcolumn=80 tw=80
  autocmd FileType markdown setlocal conceallevel=2
  autocmd FileType markdown highlight Title cterm=bold ctermfg=202
  autocmd FileType markdown nnoremap <tab> ^f(lgf<CR>
augroup END
" }}}

" Nunjucks {{{
augroup NunjucksAu
  autocmd BufNewFile,BufRead *.njk setf htmldjango
augroup END
" }}}

"}}}

"===========================================================
" Mappings {{{
"===========================================================
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

nnoremap gf :e <cfile><CR>

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

" COC {{{
" inoremap <expr> <TAB> pumvisible() ? "\<C-y>" : "\<TAB>"
" let g:coc_snippet_next = '<TAB>'
" inoremap <silent><expr> <c-space> coc#refresh()

inoremap <silent><expr> <TAB>
      \ pumvisible() ? coc#_select_confirm() :
      \ coc#expandableOrJumpable() ? "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

let g:coc_snippet_next = '<TAB>'
let g:coc_snippet_prev = '<S-TAB>'

nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
"}}}
" }}}

" COC: Prettier {{{
command! -nargs=0 Prettier :CocCommand prettier.formatFile
vmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)
" }}}

if filereadable(".git/safe/../../.vimrc.local")
  source .git/safe/../../.vimrc.local
endif
