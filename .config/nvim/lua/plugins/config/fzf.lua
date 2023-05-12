--
vim.keymap.set('n', '<leader>o',
  "<cmd>lua require('fzf-lua').files()<CR>", { silent = true })
vim.keymap.set('n', '<leader>g',
  "<cmd>lua require('fzf-lua').git_files()<CR>", { silent = true })
vim.keymap.set('n', '<leader>b',
  "<cmd>lua require('fzf-lua').buffers()<CR>", { silent = true })

-- vim.cmd [[
-- nnoremap <silent> <leader>o :Files<CR>
-- nnoremap <silent> <leader>g :GFiles<CR>
-- nnoremap <silent> <leader>h :GFiles?<CR>
-- nnoremap <silent> <leader>c :BCommits<CR>
-- nnoremap <silent> <leader>b :Buffers<CR>
-- ]]
