return {
  'stevearc/conform.nvim',
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      javascript = { { 'prettierd', 'prettier' } },
      typescript = { { 'prettierd', 'prettier' } },
      typescriptreact = {  { 'prettierd', 'prettier' }  },
      javascriptreact = { { 'prettierd', 'prettier' } },
      json = { 'prettier' },
      html = { { 'prettierd', 'prettier' } },
      css = { { 'prettierd', 'prettier' } },
      scss = { 'prettier' },
      markdown = { 'prettier' },
      yaml = { { 'prettierd', 'prettier' } },
    }
  },
}
