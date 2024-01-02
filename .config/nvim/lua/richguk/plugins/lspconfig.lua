return {
  {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v3.x',
    dependencies = {
      -- LSP Support
      'neovim/nvim-lspconfig',
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',

      -- Autocompletion
      'hrsh7th/nvim-cmp',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-nvim-lua',
    },
    config = function()
      local lsp_zero = require('lsp-zero')

      local ensure_installed = {}
      if os.getenv("FULL_DOTFILES") then
        ensure_installed = {
          'tsserver',
          'eslint',
          'golangci_lint_ls',
          'gopls',
        }
      end

      require('mason').setup({})
      require('mason-lspconfig').setup({
        ensure_installed = ensure_installed,
        handlers = {
          lsp_zero.default_setup,
          lua_ls = function()
            require('lspconfig').lua_ls.setup(lsp_zero.nvim_lua_ls())
          end
        }
      })

      require('lspconfig').solargraph.setup({})


      lsp_zero.on_attach(function(_, bufnr)
        lsp_zero.default_keymaps({ buffer = bufnr })
        local opts = { buffer = bufnr }

        vim.keymap.set({ 'n', 'v' }, '<leader>f', function()
          vim.lsp.buf.format({ async = true, timeout_ms = 10000 })
        end, opts)

        vim.keymap.set('n', '<leader>vd', vim.diagnostic.open_float)
        vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
        vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
        vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action)
      end)

      local cmp = require('cmp')
      local cmp_action = require('lsp-zero').cmp_action()


      cmp.setup({
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered()
        },
        sources = {
          -- { name = "copilot", group_index = 2 },
          { name = 'path' },
          { name = 'nvim_lsp' },
          { name = 'nvim_lua' },
          { name = 'buffer',  keyword_length = 3 },
        },
        mapping = cmp.mapping.preset.insert({
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ['<Tab>'] = cmp_action.tab_complete(),
          ['<S-Tab>'] = cmp_action.select_prev_or_fallback(),
        }),
        snippet = {
          expand = function(_)
          end
        },
      })

      cmp.event:on("menu_opened", function()
        vim.b.copilot_suggestion_hidden = true
      end)

      cmp.event:on("menu_closed", function()
        vim.b.copilot_suggestion_hidden = false
      end)
    end
  }
}
