return {
  {
    -- packadd name must match nixCats opt dir (`render-markdown.nvim`).
    "render-markdown.nvim",
    ft = { "markdown", "copilot-chat", "opencode_output" },
    -- Allow other plugins (e.g. opencode) to `require("render-markdown")`
    -- without manually packadd-ing it.
    on_require = { "render-markdown" },
    after = function()
      -- Minimal treesitter setup (loads nvim-treesitter via `on_require` handler).
      local ok_ts, ts = pcall(require, "nvim-treesitter.configs")
      if ok_ts then
        ts.setup({ highlight = { enable = true } })
      end

      require("render-markdown").setup({
        anti_conceal = { enabled = false },
        file_types = { "markdown", "opencode_output" },
      })
    end,
  },
}

