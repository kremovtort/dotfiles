return {
  {
    -- packadd name must match nixCats opt dir (`nvim-notify`).
    "nvim-notify",
    on_require = { "notify" },
    dep_of = { "noice.nvim" },
    after = function()
      require("notify").setup({})
    end,
  },
}
