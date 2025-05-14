return {
  {
    "folke/edgy.nvim",
    opts = function(_, opts)
      opts.right = vim.fn.extend(opts.right, {
        { ft = "Avante" },
        { ft = "AvanteSelectedFiles" },
        { ft = "AvanteInput" },
      })
      return opts
    end
  }
}
