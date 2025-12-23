-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
if vim.g.vscode then
  -- Remap folding keys
  local function vscode(command)
    return '<Cmd>call VSCodeNotify("' .. command .. '")<CR>'
  end
  
  local noremap_silent = { noremap = true, silent = true }

  vim.keymap.set("n", "zM", vscode("editor.foldAll"), noremap_silent)
  vim.keymap.set("n", "zR", vscode("editor.unfoldAll"), noremap_silent)
  vim.keymap.set("n", "zc", vscode("editor.fold"), noremap_silent)
  vim.keymap.set("n", "zC", vscode("editor.foldRecursively"), noremap_silent)
  vim.keymap.set("n", "zo", vscode("editor.unfold"), noremap_silent)
  vim.keymap.set("n", "zO", vscode("editor.unfoldRecursively"), noremap_silent)
  vim.keymap.set("n", "za", vscode("editor.toggleFold"), noremap_silent)
  
  -- Remap error navigation keys
  vim.keymap.set("n", "]e", vscode("editor.action.marker.next"), noremap_silent)
  vim.keymap.set("n", "[e", vscode("editor.action.marker.prev"), noremap_silent)
  vim.keymap.set("n", "]E", vscode("editor.action.marker.nextInFiles"), noremap_silent)
  vim.keymap.set("n", "[E", vscode("editor.action.marker.prevInFiles"), noremap_silent)
  vim.keymap.set("n", "<C-w>q", vscode("workbench.action.closeEditorsInGroup"), noremap_silent)
  vim.keymap.set("n", "<leader>e", vscode("workbench.files.action.focusFilesExplorer"), noremap_silent)
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
