local lsp = require('lsp-zero').preset({})

lsp.ensure_installed({
  'tsserver',
  'eslint',
  'golangci_lint_ls',
  'gopls',
})

lsp.setup_servers({
  'solargraph',
})

require('lspconfig').lua_ls.setup(lsp.nvim_lua_ls())

require('lspconfig').svelte.setup {
  on_attach = function(client)
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = { "*.js", "*.ts" },
      callback = function(ctx)
        client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.file })
      end,
    })
  end
}

lsp.on_attach(function(_, bufnr)
  lsp.default_keymaps({ buffer = bufnr })
  local opts = { buffer = bufnr }

  vim.keymap.set({ 'n', 'v' }, '<leader>f', function()
    vim.lsp.buf.format({ async = true, timeout_ms = 10000 })
  end, opts)

  vim.keymap.set('n', '<leader>vd', vim.diagnostic.open_float)
  vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
  vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
  vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)
end)

lsp.setup()

local cmp = require('cmp')
local cmp_action = require('lsp-zero').cmp_action()

require('luasnip.loaders.from_vscode').lazy_load()

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
    { name = 'luasnip', keyword_length = 2 },
  },
  mapping = {
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    ['<Tab>'] = cmp_action.luasnip_supertab(),
    ['<S-Tab>'] = cmp_action.luasnip_shift_supertab(),
  }
})
