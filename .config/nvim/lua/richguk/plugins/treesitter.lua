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
        },
        indent = {
          enable = true,
        },
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {

              ["a="] = { query = '@assignment.outer' },
              ["i="] = { query = '@assignment.inner' },
              ["l="] = { query = '@assignment.lhs' },
              ["r="] = { query = '@assignment.rhs' },

              ['aa'] = '@parameter.outer',
              ['ia'] = '@parameter.inner',

              ['af'] = '@function.outer',
              ['if'] = '@function.inner',

              ['ac'] = '@class.outer',
              ['ic'] = '@class.inner',
            },
          },
          move = {
            enable = true,
            set_jumps = true,
            goto_next_start = {
              ["]k"] = { query = "@block.outer", desc = "Next block start" },
              ["]f"] = { query = "@function.outer", desc = "Next function start" },
              ["]a"] = { query = "@parameter.inner", desc = "Next argument start" },
            },
            goto_next_end = {
              ["]K"] = { query = "@block.outer", desc = "Next block end" },
              ["]F"] = { query = "@function.outer", desc = "Next function end" },
              ["]A"] = { query = "@parameter.inner", desc = "Next argument end" },
            },
            goto_previous_start = {
              ["[k"] = { query = "@block.outer", desc = "Previous block start" },
              ["[f"] = { query = "@function.outer", desc = "Previous function start" },
              ["[a"] = { query = "@parameter.inner", desc = "Previous argument start" },
            },
            goto_previous_end = {
              ["[K"] = { query = "@block.outer", desc = "Previous block end" },
              ["[F"] = { query = "@function.outer", desc = "Previous function end" },
              ["[A"] = { query = "@parameter.inner", desc = "Previous argument end" },
            },
          },
        },
        endwise = {
          enable = true,
        },
      })
    end
  },
}
