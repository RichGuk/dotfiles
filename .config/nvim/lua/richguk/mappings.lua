vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv") -- move line up
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv") -- move line down
vim.keymap.set("n", "J", "mzJ`z") -- move line below to end of current, but keep cursor in place
vim.keymap.set("n", "<C-d>", "<C-d>zz") -- scroll down but keep cursor central
vim.keymap.set("n", "<C-u>", "<C-u>zz") -- scroll up ^
vim.keymap.set("n", "n", "nzzzv") -- search but keep cursor central
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste without updating register" })
vim.keymap.set("n", "<leader>P", [["+p]], { desc = "Paste from system" })

vim.keymap.set(
  { "n", "v" },
  "<leader>y",
  [["+y]],
  { desc = "Yank to system clipboard the selection" }
)
vim.keymap.set("n", "<leader>Y", [["+Y]], { desc = "Yank line into system clip" })

vim.keymap.set("n", "<leader>t", "<cmd>BlameToggle<CR>", { desc = "Toggle blame" })

vim.keymap.set("n", "]b", ":bprev<enter>", { noremap = false, desc = "Previous buffer" })
vim.keymap.set("n", "[b", ":bnext<enter>", { noremap = false, desc = "Next buffer" })
vim.keymap.set("n", "|d", ":bdelete<enter>", { noremap = false, desc = "Delete buffer" })

vim.keymap.set(
  "n",
  "<leader>es",
  ':sp <C-R>=expand("%:p:h") . "/" <CR>',
  { desc = "Open file in same dir in split" }
)
vim.keymap.set(
  "n",
  "<leader>ef",
  ':e <C-R>=expand("%:p:h") . "/" <CR>',
  { desc = "Open file in same dir" }
)
vim.keymap.set(
  "n",
  "<leader>ev",
  ':vsp <C-R>=expand("%:p:h") . "/" <CR>',
  { desc = "Open file in same dir in vsplit" }
)
vim.keymap.set(
  "n",
  "<leader>et",
  ':tabe <C-R>=expand("%:p:h") . "/" <CR>',
  { desc = "Open file in same dir in tab" }
)

vim.keymap.set("n", "<leader>sc", ":nohls <CR>", { desc = "Clear search" })

vim.keymap.set("n", "gf", ":e <cfile><CR>", { desc = "Open file under cursor" })

-- navigation around location/quick lists
vim.keymap.set("n", "<C-n>", ":cnext<CR>zz", { noremap = true, desc = "Next location" })
vim.keymap.set("n", "<C-p>", ":cprev<CR>zz", { noremap = true, desc = "Previous location" })
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz", { desc = "Next quickfix" })
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz", { desc = "Previous quickfix" })

vim.keymap.set(
  "n",
  "<leader>r",
  [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = "Rename word under cursor" }
)

vim.cmd.cnoreabbrev("w!! w !sudo tee > /dev/null %")

vim.keymap.set({ "n", "v" }, "L", "$")
vim.keymap.set({ "n", "v" }, "H", "^")

vim.keymap.set("", "<leader>f", function()
  require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format file" })

-- Format visual selection
vim.keymap.set("v", "<leader>f", function()
  require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format selection" })

vim.api.nvim_create_autocmd("LspAttach", {
  desc = "LSP actions",
  callback = function(event)
    vim.keymap.set({ "n", "v" }, "<leader>F", function()
      vim.lsp.buf.format({ async = true, timeout_ms = 10000 })
    end, { buffer = event.buf, desc = "Format file" })

    vim.keymap.set(
      "n",
      "gD",
      vim.lsp.buf.declaration,
      { buffer = event.buf, desc = "Go to declaration" }
    )
    vim.keymap.set(
      "n",
      "gd",
      vim.lsp.buf.definition,
      { buffer = event.buf, desc = "Go to definition" }
    )
    vim.keymap.set(
      "n",
      "<leader>gd",
      vim.lsp.buf.type_definition,
      { buffer = event.buf, desc = "Go to type definition" }
    )
    vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = event.buf, desc = "Hover" })
    vim.keymap.set(
      "n",
      "[d",
      vim.diagnostic.goto_prev,
      { buffer = event.buf, desc = "Previous diagnostic" }
    )
    vim.keymap.set(
      "n",
      "]d",
      vim.diagnostic.goto_next,
      { buffer = event.buf, desc = "Next diagnostic" }
    )
    vim.keymap.set(
      "n",
      "<leader>ca",
      vim.lsp.buf.code_action,
      { noremap = false, buffer = event.buf, desc = "Code action" }
    )
    vim.keymap.set(
      "n",
      "<leader>vd",
      vim.diagnostic.open_float,
      { buffer = event.buf, desc = "Diagnostic float" }
    )
  end,
})
