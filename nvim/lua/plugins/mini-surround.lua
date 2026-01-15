return {
  {
    -- packadd name must match nixCats opt dir (`mini.surround`).
    "mini.surround",
    keys = {
      { "gza", mode = { "n", "x" }, desc = "Add Surrounding" },
      { "gzd", desc = "Delete Surrounding" },
      { "gzf", desc = "Find Right Surrounding" },
      { "gzF", desc = "Find Left Surrounding" },
      { "gzh", desc = "Highlight Surrounding" },
      { "gzr", desc = "Replace Surrounding" },
      { "gzn", desc = "Update `MiniSurround.config.n_lines`" },
    },
    after = function()
      require("mini.surround").setup({
        mappings = {
          add = "gza",
          delete = "gzd",
          find = "gzf",
          find_left = "gzF",
          highlight = "gzh",
          replace = "gzr",
          update_n_lines = "gzn",
        },
      })
    end,
  },
}

