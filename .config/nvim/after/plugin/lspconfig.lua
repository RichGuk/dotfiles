local lsp_zero = require('lsp-zero')

local ensure_installed = {}
if os.getenv("FULL_DOTFILES") then
  ensure_installed = {
    'tsserver',
    'eslint',
    'golangci_lint_ls',
    'gopls',
  }
end

require('mason').setup({})
require('mason-lspconfig').setup({
  ensure_installed = ensure_installed,
  handlers = {
    lsp_zero.default_setup,
    lua_ls = function()
      require('lspconfig').lua_ls.setup(lsp_zero.nvim_lua_ls())
    end
  }
})

require('lspconfig').solargraph.setup({})


lsp_zero.on_attach(function(client, bufnr)
  lsp_zero.default_keymaps({ buffer = bufnr })
  local opts = { buffer = bufnr }

  vim.keymap.set({ 'n', 'v' }, '<leader>f', function()
    vim.lsp.buf.format({ async = true, timeout_ms = 10000 })
  end, opts)

  vim.keymap.set('n', '<leader>vd', vim.diagnostic.open_float)
  vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
  vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
  vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action)
end)

local cmp = require('cmp')
local cmp_action = require('lsp-zero').cmp_action()

cmp.setup({
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered()
  },
  sources = {
    { name = 'path' },
    { name = 'nvim_lsp' },
    { name = 'nvim_lua' },
    { name = 'buffer', keyword_length = 3 },
    -- { name = 'luasnip', keyword_length = 2 },
  },
  mapping = cmp.mapping.preset.insert({
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    ['<Tab>'] = cmp_action.luasnip_supertab(),
    ['<S-Tab>'] = cmp_action.luasnip_shift_supertab(),
  })
})
