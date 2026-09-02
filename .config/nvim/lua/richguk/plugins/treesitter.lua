-- nvim-treesitter `main` branch. The old `master` API (nvim-treesitter.configs
-- with ensure_installed/highlight/indent/textobjects) is gone, and master itself
-- stopped at Neovim 0.11 — it does not support 0.12.
--
-- Needs tree-sitter-cli 0.26.1+ on PATH: `brew install tree-sitter-cli` /
-- `pacman -S tree-sitter-cli`. Not npm, and not a Neovim plugin.

-- `main` has no auto_install, so anything not listed here simply has no
-- highlighting. The git_* and config entries were picked up silently by
-- auto_install under master — losing gitcommit is how that was noticed.
-- jsonc and tmux had parsers under master but main does not support them.
local ensure_installed = {
  "vim",
  "vimdoc",
  "bash",
  "dockerfile",
  "javascript",
  "typescript",
  "json",
  "lua",
  "markdown",
  "ruby",
  "yaml",
  "toml",
  "ini",
  "diff",
  "gitcommit",
  "git_config",
  "git_rebase",
  "gitignore",
  "ssh_config",
  "query",
}

if os.getenv("FULL_DOTFILES") then
  ensure_installed = {
    "vim",
    "vimdoc",
    "bash",
    "css",
    "scss",
    "diff",
    "dockerfile",
    "elixir",
    "html",
    "javascript",
    "svelte",
    "typescript",
    "json",
    "lua",
    "markdown",
    "ruby",
    "rust",
    "yaml",
    "go",
    "gomod",
    "toml",
    "ini",
    "gitcommit",
    "git_config",
    "git_rebase",
    "gitignore",
    "ssh_config",
    "query",
    "python",
    "sql",
    "xml",
    "tsx",
    "rbs",
    "embedded_template",
    "c",
    "csv",
    "tsv", -- csv's grammar pulls this in; without it, every start retries the download
    "gpg",
    "nginx",
    "pem",
    "puppet",
    "htmldjango",
  }
end

-- Was `keymaps = { ["af"] = "@function.outer" }` under textobjects.select.
local select_textobjects = {
  ["a="] = "@assignment.outer",
  ["i="] = "@assignment.inner",
  ["l="] = "@assignment.lhs",
  ["r="] = "@assignment.rhs",
  ["aa"] = "@parameter.outer",
  ["ia"] = "@parameter.inner",
  ["af"] = "@function.outer",
  ["if"] = "@function.inner",
  ["ac"] = "@class.outer",
  ["ic"] = "@class.inner",
  ["ab"] = "@block.outer",
  ["ib"] = "@block.inner",
}

-- Was textobjects.move.goto_* . key -> { query, description }
local move_textobjects = {
  goto_next_start = {
    ["]k"] = { "@block.outer", "Next block start" },
    ["]f"] = { "@function.outer", "Next function start" },
    ["]a"] = { "@parameter.inner", "Next argument start" },
  },
  goto_next_end = {
    ["]K"] = { "@block.outer", "Next block end" },
    ["]F"] = { "@function.outer", "Next function end" },
    ["]A"] = { "@parameter.inner", "Next argument end" },
  },
  goto_previous_start = {
    ["[k"] = { "@block.outer", "Previous block start" },
    ["[f"] = { "@function.outer", "Previous function start" },
    ["[a"] = { "@parameter.inner", "Previous argument start" },
  },
  goto_previous_end = {
    ["[K"] = { "@block.outer", "Previous block end" },
    ["[F"] = { "@function.outer", "Previous function end" },
    ["[A"] = { "@parameter.inner", "Previous argument end" },
  },
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    -- main does not support lazy-loading; this replaces the old BufReadPost event.
    lazy = false,
    config = function()
      require("nvim-treesitter").install(ensure_installed)

      -- `highlight = { enable = true }` and `indent = { enable = true }` are no
      -- longer modules — highlighting comes from Neovim itself, per buffer.
      -- Guarded because a filetype with no installed parser is not an error.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("richguk_treesitter", { clear = true }),
        callback = function(ev)
          -- get_lang falls back to the filetype name, so it returns "fzf" for a
          -- plugin buffer with no parser. language.add returns false rather than
          -- erroring in that case, so guard on start() itself — it is the call
          -- that asserts.
          local lang = vim.treesitter.language.get_lang(ev.match)
          if not lang or not pcall(vim.treesitter.start, ev.buf, lang) then
            return
          end
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    lazy = false,
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = { lookahead = true },
        move = { set_jumps = true },
      })

      for key, query in pairs(select_textobjects) do
        vim.keymap.set({ "x", "o" }, key, function()
          require("nvim-treesitter-textobjects.select").select_textobject(query, "textobjects")
        end, { desc = "Select " .. query })
      end

      for direction, maps in pairs(move_textobjects) do
        for key, spec in pairs(maps) do
          vim.keymap.set({ "n", "x", "o" }, key, function()
            require("nvim-treesitter-textobjects.move")[direction](spec[1], "textobjects")
          end, { desc = spec[2] })
        end
      end
    end,
  },
}
