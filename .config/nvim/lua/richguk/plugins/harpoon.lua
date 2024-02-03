return {
  'ThePrimeagen/harpoon',
  event = 'VeryLazy',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local harpoon = require('harpoon')
    harpoon.setup({})
    vim.keymap.set("n", "<leader>ha", function() harpoon:list():append() end)
    vim.keymap.set("n", "<leader>hh", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)
    vim.keymap.set("n", "<leader>h1", function() harpoon:list():select(1) end)
    vim.keymap.set("n", "<leader>h2", function() harpoon:list():select(2) end)
    vim.keymap.set("n", "<leader>h3", function() harpoon:list():select(3) end)
    vim.keymap.set("n", "<leader>h4", function() harpoon:list():select(4) end)
    vim.keymap.set("n", "<leader>h5", function() harpoon:list():select(5) end)
    vim.keymap.set("n", "<leader>h6", function() harpoon:list():select(6) end)
    vim.keymap.set("n", "<leader>h7", function() harpoon:list():select(7) end)
    vim.keymap.set("n", "<leader>h8", function() harpoon:list():select(8) end)
    vim.keymap.set("n", "<leader>h9", function() harpoon:list():select(9) end)
  end
}
