return {
  {
    'github/copilot.vim',
    config = function()
      vim.keymap.set('i', '<leader>q', 'copilot#Accept("<CR>")', { expr = true, replace_keycodes = false })
    end
  },
}
