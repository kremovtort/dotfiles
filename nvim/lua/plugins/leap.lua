return {
  {
    "ggandor/leap.nvim",
    enabled = true,
    keys = {
      { "s", "<Plug>(leap-forward)", mode = { "n", "x", "o" }, desc = "Leap Forward to" },
      { "ы", "<Plug>(leap-forward)", mode = { "n", "x", "o" }, desc = "Leap Forward to" },
      { "S", "<Plug>(leap-backward)", mode = { "n", "x", "o" }, desc = "Leap Backward to" },
      { "Ы", "<Plug>(leap-backward)", mode = { "n", "x", "o" }, desc = "Leap Backward to" },
      { "gs", "<Plug>(leap-from-window)", mode = { "n", "x", "o" }, desc = "Leap from Windows" },
    },
    config = function(_, opts)
      local leap = require("leap")
      for k, v in pairs(opts) do
        leap.opts[k] = v
      end
      vim.keymap.del({ "x", "o" }, "x")
      vim.keymap.del({ "x", "o" }, "X")
    end,
  },
}
