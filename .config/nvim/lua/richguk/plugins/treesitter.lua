local ensure_installed = {
  'vim',
  'vimdoc',
  'bash',
  'dockerfile',
  'javascript',
  'typescript',
  'json',
  'lua',
  'markdown',
  'ruby',
  'yaml',
}

if os.getenv("FULL_DOTFILES") then
  ensure_installed = {
    'vim',
    'vimdoc',
    'bash',
    'css',
    'scss',
    'diff',
    'dockerfile',
    'elixir',
    'html',
    'javascript',
    'svelte',
    'typescript',
    'json',
    'lua',
    'markdown',
    'ruby',
    'rust',
    'yaml',
    'go',
    'gomod'
  }
end

return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
      'RRethy/nvim-treesitter-endwise'
    },
    config = function()
      require('nvim-treesitter.configs').setup({
        ensure_installed = ensure_installed,
        sync_install = false,
        auto_install = true,
        highlight = {
          enable = true,
          disable = { 'json' },
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = true,
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
        endwise = {
          enable = true,
        },
      })
    end
  },
}
