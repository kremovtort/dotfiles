return {
  {
    "yetone/avante.nvim",
    opts = function(_, opts)
      opts.provider = "goose"
      opts.acp_providers = {
        ["goose"] = {
          command = "goose",
          args = { "acp" },
          env = {
            OPENROUTER_API_KEY = vim.env.OPENROUTER_API_KEY,
          },
        },
      }
    end,
  },
}
