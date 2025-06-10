return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      {
        "hrsh7th/nvim-cmp",
        dependencies = {
          "hrsh7th/cmp-path",
          "hrsh7th/cmp-buffer",
          "hrsh7th/cmp-nvim-lsp",
          "hrsh7th/cmp-nvim-lua",
          {
            "L3MON4D3/LuaSnip",
            version = "v2.*",
          },
          "saadparwaiz1/cmp_luasnip",
        },
      },
    },
    config = function()
      local ensure_installed = {}
      if os.getenv("FULL_DOTFILES") then
        ensure_installed = {
          "ts_ls",
          "eslint",
          "golangci_lint_ls",
          "gopls",
        }
      end

      local signs = {
        { name = "DiagnosticSignError", text = "" },
        { name = "DiagnosticSignWarn", text = "" },
        { name = "DiagnosticSignHint", text = "" },
        { name = "DiagnosticSignInfo", text = "" },
      }

      for _, sign in ipairs(signs) do
        vim.fn.sign_define(
          sign.name,
          { text = sign.text, texthl = sign.name, linehl = "", numhl = "" }
        )
      end

      vim.diagnostic.config({
        virtual_text = false,
        signs = {
          active = signs,
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

      local lsp_capabilities = require("cmp_nvim_lsp").default_capabilities()
      require("mason").setup({})
      require("mason-lspconfig").setup({
        ensure_installed = ensure_installed,
        handlers = {
          function(server)
            require("lspconfig")[server].setup({
              capabilities = lsp_capabilities,
            })
          end,
          lua_ls = function()
            require("lspconfig").lua_ls.setup({
              capabilities = lsp_capabilities,
              settings = {
                Lua = {
                  diagnostics = {
                    globals = { "vim" },
                  },
                },
              },
            })
          end,
        },
      })

      -- require("lspconfig").solargraph.setup({})
    local util = require("lspconfig.util")

    require("lspconfig").ruby_lsp.setup({
      cmd = (function()
        local cwd = vim.fn.getcwd()
        local local_bin = cwd .. "/bin/docker-ruby-lsp"
        local safe_marker = cwd .. "/.git/safe"

        if vim.fn.executable(local_bin) == 1 and vim.fn.isdirectory(safe_marker) == 1 then
          return { local_bin }
        else
          return { "ruby-lsp" }
        end
      end)(),
      root_dir = util.root_pattern("Gemfile", ".git"),
      capabilities = lsp_capabilities,
    })


      local cmp = require("cmp")
      local luasnip = require("luasnip")

      local has_words_before = function()
        unpack = unpack or table.unpack
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0
          and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s")
            == nil
      end

      cmp.setup({
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        sources = {
          { name = "path" },
          { name = "nvim_lsp" },
          { name = "nvim_lua" },
          { name = "buffer", keyword_length = 3 },
          { name = "luasnip" },
        },
        mapping = cmp.mapping.preset.insert({
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            elseif has_words_before() then
              cmp.complete()
            else
              fallback()
            end
          end,
          ["<S-Tab>"] = function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end,
        }),
      })
    end,
  },
}
