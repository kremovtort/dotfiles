-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
if vim.g.vscode then
  -- Remap folding keys
  vim.keymap.set("n", "zM", '<Cmd>call VSCodeNotify("editor.foldAll")<CR>', { noremap = true, silent = true })
  vim.keymap.set("n", "zR", '<Cmd>call VSCodeNotify("editor.unfoldAll")<CR>', { noremap = true, silent = true })
  vim.keymap.set("n", "zc", '<Cmd>call VSCodeNotify("editor.fold")<CR>', { noremap = true, silent = true })
  vim.keymap.set("n", "zC", '<Cmd>call VSCodeNotify("editor.foldRecursively")<CR>', { noremap = true, silent = true })
  vim.keymap.set("n", "zo", '<Cmd>call VSCodeNotify("editor.unfold")<CR>', { noremap = true, silent = true })
  vim.keymap.set("n", "zO", '<Cmd>call VSCodeNotify("editor.unfoldRecursively")<CR>', { noremap = true, silent = true })
  vim.keymap.set("n", "za", '<Cmd>call VSCodeNotify("editor.toggleFold")<CR>', { noremap = true, silent = true })
  
  -- Remap error navigation keys
  vim.keymap.set("n", "]e", '<Cmd>call VSCodeNotify("editor.action.marker.next")<CR>', { noremap = true, silent = true })
  vim.keymap.set("n", "[e", '<Cmd>call VSCodeNotify("editor.action.marker.prev")<CR>', { noremap = true, silent = true })
  vim.keymap.set("n", "]E", '<Cmd>call VSCodeNotify("editor.action.marker.nextInFiles")<CR>', { noremap = true, silent = true })
  vim.keymap.set("n", "[E", '<Cmd>call VSCodeNotify("editor.action.marker.prevInFiles")<CR>', { noremap = true, silent = true })
  vim.keymap.set("n", "<C-w>q", '<Cmd>call VSCodeNotify("workbench.action.closeEditorsInGroup")<CR>', { noremap = true, silent = true })
end

vim.keymap.set("t", "<C-x>", "<C-\\><C-n>")
vim.keymap.set({ "n", "x", "o", "i" }, "<C-x><C-[>", function()
  require("edgy").toggle("left")
end, { desc = "Toggle edgy.nvim on the left side of the editor" })
vim.keymap.set({ "n", "x", "o", "i" }, "<C-x><C-]>", function()
  require("edgy").toggle("right")
end)
vim.keymap.set({ "n", "x", "o", "i" }, "<C-x><C-'>", function()
  require("edgy").toggle("bottom")
end)
