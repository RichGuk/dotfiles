vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv") -- move line up
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv") -- move line down
vim.keymap.set('n', 'J', 'mzJ`z')            -- move line below to end of current
vim.keymap.set('n', '<C-d>', '<C-d>zz')      -- scroll down but keep cursor central
vim.keymap.set('n', '<C-u>', '<C-u>zz')      -- scroll up ^
vim.keymap.set('n', 'n', 'nzzzv')            -- search but keep cursor central
vim.keymap.set('n', 'N', 'Nzzzv')

vim.keymap.set('x', '<leader>p', [["_dP]])         -- paste without yanking into reg
vim.keymap.set('n', '<leader>P', [["+p]])          -- paste from system

vim.keymap.set({ 'n', 'v' }, '<leader>y', [["+y]]) -- yank into system
vim.keymap.set('n', '<leader>Y', [["+Y]])          -- yank line into system

vim.keymap.set('n', '<leader>t', '<cmd>ToggleBlame<CR>')

-- bindings for moving around buffers
-- vim.keymap.set('n', '<leader>b[', ':bfirst<enter>', { noremap = false })
-- vim.keymap.set('n', '<leader>b]', ':blast<enter>', { noremap = false })
vim.keymap.set('n', '[b', ':bprev<enter>', { noremap = false })
vim.keymap.set('n', ']b', ':bnext<enter>', { noremap = false })
vim.keymap.set('n', '|d', ':bdelete<enter>', { noremap = false })

-- opening files in the same directory
vim.keymap.set('n', '<leader>es', ':sp <C-R>=expand("%:p:h") . "/" <CR>')
vim.keymap.set('n', '<leader>ef', ':e <C-R>=expand("%:p:h") . "/" <CR>')
vim.keymap.set('n', '<leader>ev', ':vsp <C-R>=expand("%:p:h") . "/" <CR>')
vim.keymap.set('n', '<leader>et', ':tabe <C-R>=expand("%:p:h") . "/" <CR>')

vim.keymap.set('n', '<leader>sc', ':nohls <CR>') -- clear search

vim.keymap.set('n', 'gf', ':e <cfile><CR>')

-- navigation around location/quick lists
vim.keymap.set('n', '<C-n>', ':cnext<CR>zz', { noremap = true })
vim.keymap.set('n', '<C-p>', ':cprev<CR>zz', { noremap = true })
vim.keymap.set('n', '<leader>k', '<cmd>lnext<CR>zz')
vim.keymap.set('n', '<leader>j', '<cmd>lprev<CR>zz')

vim.keymap.set('n', '<leader>r', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]]) -- rename current word

vim.keymap.set('c', 'w!!', '%!sudo tee > /dev/null %')                                   -- forgot to start with sudo

vim.keymap.set('', '<leader>f', function()
  require('conform').format({ async = true, lsp_fallback = true })
end)

vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'LSP actions',
  callback = function(event)
    local opts = { buffer = event.buf }

    vim.keymap.set({ 'n', 'v' }, '<leader>F', function()
      vim.lsp.buf.format({ async = true, timeout_ms = 10000 })
    end, opts)

    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
    vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action)
    vim.keymap.set('n', '<leader>vd', vim.diagnostic.open_float)
  end
})
