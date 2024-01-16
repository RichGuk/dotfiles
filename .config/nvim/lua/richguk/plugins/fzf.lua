return {
  {
    'ibhagwan/fzf-lua',
    event = 'VeryLazy',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      vim.keymap.set('n', '<leader>o',
        "<cmd>lua require('fzf-lua').files()<CR>", { silent = true })
      vim.keymap.set('n', '<leader>g',
        "<cmd>lua require('fzf-lua').git_files()<CR>", { silent = true })
      vim.keymap.set('n', '<leader>b',
        "<cmd>lua require('fzf-lua').buffers()<CR>", { silent = true })

      vim.keymap.set('n', 'S',
        "<cmd>lua require('fzf-lua').grep_cword()<CR>", { silent = true })

      vim.keymap.set('n', '<leader>a',
        "<cmd>lua require('fzf-lua').grep()<CR>", { silent = true })
    end
  }
}
