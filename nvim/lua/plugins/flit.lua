return {
  {
    -- packadd name must match nixCats opt dir (`flit.nvim`).
    "flit.nvim",
    keys = {
      { "f", mode = { "n", "x", "o" } },
      { "F", mode = { "n", "x", "o" } },
      { "t", mode = { "n", "x", "o" } },
      { "T", mode = { "n", "x", "o" } },
    },
    after = function()
      -- flit.nvim builds on leap.nvim; ensure it's available first.
      pcall(require("lze").trigger_load, "leap.nvim")
      require("flit").setup({
        labeled_modes = "nx",
      })
    end,
  },
}

