require('nvim-treesitter.configs').setup({
  ensure_installed = {
    'bash',
    'css',
    'diff',
    'dockerfile',
    'elixir',
    'go',
    'html',
    'javascript',
    'json',
    'lua',
    'markdown',
    'python',
    'ruby',
    'rust',
    'svelte',
    'typescript',
    'vim',
    'yaml',
  },
  sync_install = false,
  auto_install = true,
  highlight = {
    enable = true,
    -- disable = { 'ruby' }
    disable = { 'json' },
    additional_vim_regex_highlighting = false,
  },
  indent = {
    enable = true,
    -- disable = { 'ruby' },
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
  endwise = {
    enable = true,
  },
})
