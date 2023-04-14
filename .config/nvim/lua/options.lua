local o = vim.opt
local g = vim.g

o.number = true
o.relativenumber = true
o.history = 500
o.pastetoggle = '<F2>'
o.lazyredraw = true
o.colorcolumn = '100'
-- o.clipboard = 'unnamedplus'
o.completeopt = { 'menu', 'menuone', 'noselect', 'noinsert' }

o.softtabstop = 2
o.shiftwidth = 2
o.expandtab = true

o.ignorecase = true
o.smartcase = true

o.wildmode = 'list:longest,list:full'

o.list = true
o.listchars:append('eol:¬')

o.conceallevel = 0

o.swapfile = false

o.spell = false
o.spelllang = 'en_gb'

g.ruby_indent_assignment_style = 'variable'

o.termguicolors = true

o.mouse = 'v'

o.updatetime = 500
