vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.cmd [[
nnoremap <leader>ew :e <C-R>=expand("%:p:h") . "/" <CR>
nnoremap <leader>es :sp <C-R>=expand("%:p:h") . "/" <CR>
nnoremap <leader>ev :vsp <C-R>=expand("%:p:h") . "/" <CR>
nnoremap <leader>et :tabe <C-R>=expand("%:p:h") . "/" <CR>

nnoremap <leader>rw <esc>:RMTWS<CR>
nnoremap <silent> <F4> :set spell!<CR> :set spell?<CR>
nnoremap <Leader>ssc :nohls<CR>
cnoremap w!! %!sudo tee > /dev/null %
nnoremap <silent> S :Ag <C-R><C-W><CR>
nnoremap ]q :cnext<CR>
nnoremap [q :cprevious<CR>

nnoremap gf :e <cfile><CR>

nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
]]
