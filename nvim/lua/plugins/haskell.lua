return {
  {
    "mrcjkb/haskell-tools.nvim",
    opts = {
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
    },
    config = function(_, opts)
      vim.g.haskell_tools = opts
    end,
  },
}
