return {
  {
    'github/copilot.vim',
    config = function()
      vim.g.copilot_filetypes = {
        ['markdown'] = false,
      }
      vim.keymap.set('i', '<C-J>', 'copilot#Accept("<CR>")', { expr = true, replace_keycodes = false })
    end
  },
}
