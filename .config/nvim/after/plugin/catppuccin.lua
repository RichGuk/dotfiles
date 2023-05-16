require("catppuccin").setup({
  transparent_background = true,
  integrations = {
    cmp = true,
  },
  no_italic = true,
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

vim.cmd.colorscheme 'catppuccin'
