return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        transparent_background = true,
        integrations = {
          cmp = true,
        },
        no_italic = true,
        native_lsp = {
          enabled = true,
        },
        custom_highlights = function(colors)
          return {
            TabLine = { bg = colors.base, fg = colors.overlay0 },
            TabLineSel = { bg = colors.pink },
            ["@lsp.type.namespace.ruby"] = { link = "@structure" },
          }
        end,
      })

      vim.cmd.colorscheme("catppuccin")
    end,
  },
}
