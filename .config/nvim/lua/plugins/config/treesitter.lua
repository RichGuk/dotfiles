require('nvim-treesitter.configs').setup({
  ensure_installed = {
    'ruby',
    'elixir',
    'python',
    'go',
    'rust',
    'javascript',
    'bash',
    'json',
    'markdown',
    'yaml',
    'lua',
    'html',
    'css',
    'svelte',
    'vim',
  },
  highlight = {
    enable = true,
    -- disable = { 'ruby' }
    disable = { 'json', 'css' },
    additional_vim_regex_highlighting = true,
  },
  indent = {
    enable = true,
    disable = { 'ruby' },
  },
  textobjects = {
    select = {
      enable = true,
      lookahead = true,
      keymaps = {
        ['aa'] = '@parameter.outer',
        ['ia'] = '@parameter.inner',
        ['af'] = '@function.outer',
        ['if'] = '@function.inner',
        ['ac'] = '@class.outer',
        ['ic'] = '@class.inner',
      },
    },
  },
  move = {
    enable = true,
    set_jumps = true,
    goto_next_start = {
      [']m'] = '@function.outer',
      [']]'] = '@class.outer',
    },
    goto_next_end = {
      [']M'] = '@function.outer',
      [']['] = '@class.outer',
    },
    goto_previous_start = {
      ['[m'] = '@function.outer',
      ['[['] = '@class.outer',
    },
    goto_previous_end = {
      ['[M'] = '@function.outer',
      ['[]'] = '@class.outer',
    },
  },
  swap = {
    enable = true,
    swap_next = {
      ['<leader>a'] = '@parameter.inner',
    },
    swap_previous = {
      ['<leader>A'] = '@parameter.inner',
    },
  },
})
