return {
  {
    -- packadd name must match nixCats opt dir (`nui.nvim`).
    "nui.nvim",
    -- noice requires `nui.*`
    on_require = { "nui" },
    dep_of = { "noice.nvim" },
  },
}
