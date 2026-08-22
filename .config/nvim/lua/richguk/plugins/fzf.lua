return {
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      {
        "<leader>o",
        function()
          require("fzf-lua").files()
        end,
        desc = "Find files",
      },
      {
        "<leader>g",
        function()
          require("fzf-lua").git_files()
        end,
        desc = "Git files",
      },
      {
        "<leader>b",
        function()
          require("fzf-lua").buffers()
        end,
        desc = "Buffers",
      },
      {
        "S",
        function()
          require("fzf-lua").grep_cword()
        end,
        desc = "Grep word under cursor",
      },
      {
        "<leader>a",
        function()
          require("fzf-lua").grep()
        end,
        desc = "Grep search",
      },
    },
  },
}
