-- Autocommands (independent from any Neovim distribution).

local augroup = vim.api.nvim_create_augroup("kremovtort_autocmds", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup,
  callback = function()
    vim.highlight.on_yank({ timeout = 200 })
  end,
})

-- Keep split sizes reasonable when the terminal is resized.
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup,
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
})
