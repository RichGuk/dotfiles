return {
  {
    "neovim/nvim-lspconfig",
    dev = true,
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      local ensure_installed = {}
      if os.getenv("FULL_DOTFILES") then
        ensure_installed = {
          "ts_ls",
          "eslint",
          "golangci_lint_ls",
          "gopls",
          "lua_ls",
        }
      end

      vim.diagnostic.config({
        virtual_text = false,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.INFO] = "󰋼 ",
            [vim.diagnostic.severity.HINT] = "󰌵 ",
          },
          numhl = {
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.WARN] = "",
            [vim.diagnostic.severity.HINT] = "",
            [vim.diagnostic.severity.INFO] = "",
          },
        },
        float = {
          header = false,
          border = "rounded",
          focusable = true,
        },
      })

      vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
        focusable = true,
        border = "rounded",
      })
      vim.lsp.handlers["textDocument/signatureHelp"] =
          vim.lsp.with(vim.lsp.handlers.signature_help, {
            focusable = true,
            border = "rounded",
          })

      require("mason").setup({})
      require("mason-lspconfig").setup({
        ensure_installed = ensure_installed,
      })

      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = {
              globals = { 'vim' },
            },
          },
        },
      })

      vim.lsp.config('ruby_lsp', {
        init_options = {
          formatter = "auto",
          addonSettings = {
            ["Ruby LSP Rails"] = {
              enablePendingMigrationsPrompt = false,
            },
          },
        },
      })
      vim.lsp.enable("ruby_lsp")
    end,
  },
}
