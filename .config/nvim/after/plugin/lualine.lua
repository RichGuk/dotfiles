local custom_catppuccin = require('lualine.themes.catppuccin')
custom_catppuccin.normal.c.bg = '#11111b'
custom_catppuccin.inactive.c.bg = '#181825'

require('lualine').setup({
  options = { theme = custom_catppuccin },
  globalstatus = true,
  sections = {
    lualine_a = {'buffers'},
    lualine_b = {'diff', 'diagnostics'},
    lualine_c = {
      {
        'filename',
        path = 1,
      }
    },
  },
  inactive_sections = {
    lualine_c = {
      {
        'filename',
        path = 1,
      }
    },
  }
})
