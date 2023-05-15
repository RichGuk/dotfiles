require("catppuccin").setup({
  transparent_background = true,
  integrations = {
    cmp = true,
  },
  native_lsp = {
    enabled = true,
  },
  highlight_overrides = {
    all = function()
      return {
      }
    end,
  }
})

-- vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
--   border = "rounded",
-- })

vim.cmd.colorscheme 'catppuccin'
