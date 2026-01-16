return {
  {
    -- packadd name must match nixCats opt dir (`ts-comments.nvim`).
    "ts-comments.nvim",
    event = "DeferredUIEnter",
    after = function()
      require("ts-comments").setup({})
    end,
  },
}

