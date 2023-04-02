vim.cmd [[
  colorscheme railscasts
]]

vim.cmd[[
  hi IndentBlankLineChar ctermfg=240
  highlight Normal ctermbg=NONE guibg=NONE ctermfg=255
  highlight TabLineFill term=bold cterm=bold ctermfg=255 ctermbg=0
  highlight CursorColumn term=underline cterm=underline guibg=#333435
  highlight NonText ctermbg=NONE ctermfg=235 guifg=#424242 gui=NONE
  highlight SpecialKey ctermbg=NONE ctermfg=235 guifg=#424242 gui=NONE
  highlight ColorColumn ctermbg=233 guibg=#464646
  highlight link TrailingWhiteSpace Search
  highlight IndentBlanklineSpaceChar guifg=#00FF00 gui=nocombine
]]
