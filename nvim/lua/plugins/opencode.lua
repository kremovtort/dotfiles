return {
  {
    -- packadd name must match nixCats opt dir (pack/*/opt/opencode-nvim).
    "opencode-nvim",
    cmd = { "Opencode" },
    keys = {
      { "<leader>oo", "<cmd>Opencode<cr>", desc = "Open opencode.nvim" },
    },
    after = function()
      -- Minimal config. See upstream docs for full option list.
      -- https://github.com/sudo-tee/opencode.nvim
      require("opencode").setup({})
    end,
  },
}

