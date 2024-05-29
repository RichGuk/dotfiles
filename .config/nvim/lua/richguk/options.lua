vim.opt.cursorline = true -- Highlight the current line
vim.opt.number = true -- Show line numbers
vim.opt.numberwidth = 2
vim.opt.relativenumber = true -- Show relative line numbers
vim.opt.history = 500 -- Remember n lines in history
vim.opt.lazyredraw = true -- Don't redraw while executing macros
vim.opt.colorcolumn = "100" -- Show a column at 100 characters
vim.opt.completeopt = { "menu", "menuone", "noselect", "noinsert" } -- Completion options

-- Indentation
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

vim.opt.ignorecase = true -- Ignore case when searching
vim.opt.smartcase = true -- Override the 'ignorecase' option if the search pattern contains upper case characters

vim.opt.wildmode = "list:longest,list:full" -- Command-line completion mode

vim.opt.list = true -- Show invisible characters
vim.opt.listchars:append("eol:¬") -- Show a special character at the end of each line

vim.opt.conceallevel = 0 -- Show concealed text

vim.opt.swapfile = false -- Don't create swap files

vim.opt.spell = false -- Don't spell check
vim.opt.spelllang = "en_gb" -- Set the spell check language

vim.opt.shortmess:append("sI") -- Disable intro message

vim.opt.termguicolors = true -- Enable 24-bit RGB color
vim.opt.timeoutlen = 400 -- Time in milliseconds to wait for a mapped sequence to complete
vim.opt.undofile = true -- Enable persistent undo
vim.opt.updatetime = 500 -- Faster completion

vim.opt.mouse = "v" -- Enable mouse support in the TUI

vim.opt.splitbelow = true -- Open new split windows below the current window
vim.opt.splitright = true -- Open new split windows to the right of the current window

vim.opt.signcolumn = "yes" -- Show the sign column

vim.opt.scrolloff = 8 -- Keep no lines above and below the cursor when scrolling


-- Set the fold text to use treesitter
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldtext = ""
vim.opt.foldcolumn = "0"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 1
vim.opt.foldnestmax = 4
vim.opt.foldenable = false
