return {
  {
    -- packadd name must match nixCats opt dir (`plenary.nvim`).
    "plenary.nvim",
    -- Lazy-load when any `plenary.*` module is required.
    -- See lze docs: https://github.com/BirdeeHub/lze
    on_require = { "plenary" },
  },
}

