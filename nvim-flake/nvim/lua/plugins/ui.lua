return {
  {
    "catppuccin-nvim",
    lazy = false,
    priority = 1000,
    after = function()
      require("catppuccin").setup({
        color_overrides = {
          mocha = {
            base = "#1c1c1c",
            mantle = "#161616",
            crust = "#101010",
            surface0 = "#2c2c2c",
            surface1 = "#3c3c3c",
            surface2 = "#4c4c4c",
            overlay0 = "#606060",
            overlay1 = "#757575",
            overlay2 = "#8a8a8a",
          },
        },
      })

      vim.cmd.colorscheme("catppuccin-mocha")
    end,
  },

  {
    "nvim-scrollbar",
    event = "DeferredUIEnter",
    after = function()
      require("scrollbar").setup({})
    end,
  },
}
