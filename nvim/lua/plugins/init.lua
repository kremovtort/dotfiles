-- Ordered plugin specs for `lze`.
-- Unlike lz.n, lze does not automatically import an entire directory, so we
-- explicitly control the load order here. See: https://github.com/BirdeeHub/lze

return {
  { import = "plugins.ui" },
  { import = "plugins.mini-icons" },
  { import = "plugins.lualine" },
  { import = "plugins.snacks" },
  { import = "plugins.edgy" },
  { import = "plugins.which-key" },
  { import = "plugins.nui" },
  { import = "plugins.notify" },
  { import = "plugins.noice" },
  { import = "plugins.blink" },
  { import = "plugins.leap" },
  { import = "plugins.flit" },
  { import = "plugins.mini-pairs" },
  { import = "plugins.mini-ai" },
  { import = "plugins.mini-surround" },
  { import = "plugins.ts-comments" },
  { import = "plugins.grug-far" },
  { import = "plugins.repeat" },
  { import = "plugins.hunk" },
  { import = "plugins.haskell" },
  { import = "plugins.plenary" },
  { import = "plugins.treesitter" },
  { import = "plugins.mini" },
  { import = "plugins.render-markdown" },
  { import = "plugins.opencode" },
}

