-- zsh's edit-command-line opens nvim on a $TMPPREFIX scratch file (zshXXXXXX.zsh);
-- not worth booting a language server to edit a shell prompt.
local function editing_shell_command()
  return vim.fn.fnamemodify(vim.fn.argv(0), ":t"):match("^zsh%w+%.zsh$") ~= nil
end

return {
  {
    "github/copilot.vim",
    event = "InsertEnter",
    cond = function()
      return not editing_shell_command()
    end,
    config = function()
      vim.g.copilot_filetypes = {
        ["markdown"] = false,
      }
      vim.keymap.set(
        "i",
        "<C-J>",
        'copilot#Accept("<CR>")',
        { expr = true, replace_keycodes = false }
      )
    end,
  },
  -- {
  --   "yetone/avante.nvim",
  --   lazy = false,
  --   version = false,
  --   build = "make",
  --   opts = {
  --     hints = { enabled = false }
  --   },
  --   dependencies = {
  --     "nvim-treesitter/nvim-treesitter",
  --     "stevearc/dressing.nvim",
  --     "nvim-lua/plenary.nvim",
  --     "MunifTanjim/nui.nvim",
  --   }
  -- }
}
