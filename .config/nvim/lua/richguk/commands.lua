vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function()
    vim.opt.formatoptions:remove("t")
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "php",
  callback = function()
    vim.opt_local.softtabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    vim.opt_local.softtabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "go",
  callback = function()
    vim.opt_local.expandtab = false
    vim.opt_local.softtabstop = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "ruby",
  command = "setlocal indentkeys-=.",
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  pattern = "*.njk",
  command = "setfiletype htmldjango",
})

vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
  pattern = "*.mjml",
  command = "setfiletype eruby.html",
})

local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = "*",
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  pattern = "*/app/{components,hooks}/**/*.js",
  command = "setfiletype javascriptreact",
})
