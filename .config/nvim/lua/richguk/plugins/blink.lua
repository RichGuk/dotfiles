return {
  'saghen/blink.cmp',
  enabled = true,
  version = '1.*',
  opts = {
    keymap = {
      preset = "default",
      ["<Tab>"] = { "select_next", "fallback" },
      ["<S-Tab>"] = { "select_prev", "fallback" },
      ['<CR>'] = { 'accept', 'fallback' },
    },
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
    },
    completion = {
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 200,
        window = { border = "single" },
      },
      list = {
        selection = {
          auto_insert = true,
          preselect = true
        }
      }
    },
  },
  opts_extend = { "sources.default" },
}
