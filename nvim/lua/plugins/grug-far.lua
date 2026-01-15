return {
  {
    -- packadd name must match nixCats opt dir (`grug-far.nvim`).
    "grug-far.nvim",
    cmd = { "GrugFar", "GrugFarWithin" },
    keys = {
      {
        "<leader>sr",
        function()
          local grug = require("grug-far")
          local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
          grug.open({
            transient = true,
            prefills = {
              filesFilter = ext and ext ~= "" and "*." .. ext or nil,
            },
          })
        end,
        mode = { "n", "x" },
        desc = "Search and Replace",
      },
    },
    after = function()
      require("grug-far").setup({ headerMaxWidth = 80 })
    end,
  },
}

