return {
  {
    "haskell-tools.nvim",
    ft = { "haskell" },
    before = function()
      -- haskell-tools reads its config from this global
      vim.g.haskell_tools = {
        hls = {
          settings = {
            haskell = {
              plugin = {
                importLens = {
                  globalOn = false,
                },
              },
            },
          },
        },
      }
    end,
  },
}
