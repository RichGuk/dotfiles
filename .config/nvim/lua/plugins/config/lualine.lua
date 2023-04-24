require('lualine').setup({
  options = { theme = 'ayu_dark' },
  globalstatus = true,
  sections = {
    lualine_c = {
      {
        'filename',
        path = 1,
      }
    },
  }
})
