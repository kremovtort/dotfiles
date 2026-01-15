return {
  {
    "leap.nvim",
    keys = {
      { "s", "<Plug>(leap-forward)", mode = { "n", "x", "o" }, desc = "Leap Forward to" },
      { "ы", "<Plug>(leap-forward)", mode = { "n", "x", "o" }, desc = "Leap Forward to" },
      { "S", "<Plug>(leap-backward)", mode = { "n", "x", "o" }, desc = "Leap Backward to" },
      { "Ы", "<Plug>(leap-backward)", mode = { "n", "x", "o" }, desc = "Leap Backward to" },
      { "gs", "<Plug>(leap-from-window)", mode = { "n", "x", "o" }, desc = "Leap from Windows" },
    },
    after = function()
      pcall(vim.keymap.del, { "x", "o" }, "x")
      pcall(vim.keymap.del, { "x", "o" }, "X")
    end,
  },
}
