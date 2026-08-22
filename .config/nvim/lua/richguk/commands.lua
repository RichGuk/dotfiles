-- Grouped so re-sourcing this file replaces the autocmds instead of stacking
-- another copy of each one.
local augroup = vim.api.nvim_create_augroup("richguk", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = "*",
  callback = function()
    vim.opt_local.formatoptions:remove("t") -- Do not auto-wrap text
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = "php",
  callback = function()
    vim.opt_local.softtabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = "python",
  callback = function()
    vim.opt_local.softtabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = "go",
  callback = function()
    vim.opt_local.expandtab = false
    vim.opt_local.softtabstop = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = "ruby",
  command = "setlocal indentkeys-=.", -- Do not auto-indent after typing a period
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = augroup,
  pattern = "*.njk",
  command = "setfiletype htmldjango",
})

vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
  group = augroup,
  pattern = "*.mjml",
  command = "setfiletype eruby.html",
})

local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.hl.on_yank()
  end,
  group = highlight_group,
  pattern = "*",
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = augroup,
  pattern = "*/app/{components,hooks}/**/*.js",
  command = "setfiletype javascriptreact",
})

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  group = augroup,
  callback = function(event)
    if event.match:match("^%w%w+:[\\/][\\/]") then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})
