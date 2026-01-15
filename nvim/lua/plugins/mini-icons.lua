return {
  {
    -- packadd name must match nixCats opt dir (`mini.icons`).
    "mini.icons",
    on_require = { "mini.icons", "nvim-web-devicons" },
    beforeAll = function()
      -- Allow plugins expecting `nvim-web-devicons` to work without installing it.
      package.preload["nvim-web-devicons"] = function()
        require("mini.icons").mock_nvim_web_devicons()
        return package.loaded["nvim-web-devicons"]
      end
    end,
    after = function()
      require("mini.icons").setup({
        file = {
          [".keep"] = { glyph = "󰊢", hl = "MiniIconsGrey" },
          ["devcontainer.json"] = { glyph = "", hl = "MiniIconsAzure" },
        },
        filetype = {
          dotenv = { glyph = "", hl = "MiniIconsYellow" },
        },
      })
    end,
  },
}

