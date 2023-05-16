vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv")
vim.keymap.set('n', 'J', 'mzJ`z')
vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')

vim.keymap.set('x', '<leader>p', [["_dP]])
vim.keymap.set('n', '<leader>P', [["+p]])
vim.keymap.set({'n', 'v'}, '<leader>y', [["+y]])
vim.keymap.set('n', '<leader>Y', [["+Y]])

vim.keymap.set('n', '<leader>es', ':sp <C-R>=expand("%:p:h") . "/" <CR>')
vim.keymap.set('n', '<leader>ef', ':e <C-R>=expand("%:p:h") . "/" <CR>')
vim.keymap.set('n', '<leader>ev', ':vsp <C-R>=expand("%:p:h") . "/" <CR>')
vim.keymap.set('n', '<leader>et', ':tabe <C-R>=expand("%:p:h") . "/" <CR>')

vim.keymap.set('n', '<leader>sc', ':nohls <CR>')

vim.keymap.set('n', 'gf', ':e <cfile><CR>')

vim.keymap.set('n', '<C-k>', '<cmd>cnext<CR>zz')
vim.keymap.set('n', '<C-j>', '<cmd>cprev<CR>zz')
vim.keymap.set('n', '<leader>k', '<cmd>lnext<CR>zz')
vim.keymap.set('n', '<leader>j', '<cmd>lprev<CR>zz')

vim.keymap.set('n', '<leader>r', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

vim.keymap.set('c', 'w!!', '%!sudo tee > /dev/null %')

vim.keymap.set('n', '<leader>f', function()
  vim.lsp.buf.format { async = true }
end)
