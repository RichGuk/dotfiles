require('onedark').setup({
    style = 'darker',
    transparent = true,
    colors = {
      fg = '#e4e4e4',
      myOrange = '#af5f00',
    },
    highlights = {
      -- TSKeyword = { fg = '$myOrange' },
      -- TSConditional = { fg = '$myOrange' },
      -- Conditional = { fg = '$myOrange' },
      -- Statement = { fg = '$myOrange' },
      -- TSKeywordFunction = { fg = '$myOrange' },
      -- rubyDefine = { fg = '$myOrange' },
      -- rubyMacro = { fg = '$myOrange' },
      -- rubyConstant = { fg = '$red' },
      -- rubyClass = { fg = '$fg' },
      -- rubyStringDelimiter = { fg = '$green' },
      -- Function = { fg = '$yellow' },
      -- TSFunction = { fg = '$blue' },
      -- TSPunctBracket = { fg = '$fg' },
      -- TSInclude = { fg = '$myOrange' },
      -- TSConstant = { fg = '$red' },
    },
    code_style = {
      comments = 'none',
    },
})

require('onedark').load()
