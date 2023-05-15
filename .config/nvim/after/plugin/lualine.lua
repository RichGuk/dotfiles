require('lualine').setup({
  options = { theme = 'catppuccin' },
  globalstatus = true,
  sections = {
    lualine_b = {'diff', 'diagnostics'},
    lualine_c = {
      {
        'filename',
        path = 1,
      }
    },
  }
})
