return {
  {
    -- packadd name must match nixCats opt dir (`noice.nvim`).
    "noice.nvim",
    event = "DeferredUIEnter",
    -- stylua: ignore
    keys = {
      { "<leader>sn", "", desc = "+noice" },
      { "<S-CR>", function() require("noice").redirect(vim.fn.getcmdline()) end, mode = "c", desc = "Redirect Cmdline" },
      { "<leader>snl", function() require("noice").cmd("last") end, desc = "Noice Last Message" },
      { "<leader>snh", function() require("noice").cmd("history") end, desc = "Noice History" },
      { "<leader>sna", function() require("noice").cmd("all") end, desc = "Noice All" },
      { "<leader>snd", function() require("noice").cmd("dismiss") end, desc = "Dismiss All" },
      { "<leader>snt", function() require("noice").cmd("pick") end, desc = "Noice Picker (Telescope/FzfLua)" },
      { "<c-f>", function() if not require("noice.lsp").scroll(4) then return "<c-f>" end end, silent = true, expr = true, desc = "Scroll Forward", mode = {"i", "n", "s"} },
      { "<c-b>", function() if not require("noice.lsp").scroll(-4) then return "<c-b>" end end, silent = true, expr = true, desc = "Scroll Backward", mode = {"i", "n", "s"} },
    },
    after = function()
      local opts = {
        lsp = {
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            -- Keep this for compatibility with plugins that still query cmp docs.
            ["cmp.entry.get_documentation"] = true,
          },
        },
        routes = {
          {
            filter = {
              event = "msg_show",
              any = {
                { find = "%d+L, %d+B" },
                { find = "; after #%d+" },
                { find = "; before #%d+" },
              },
            },
            view = "mini",
          },
        },
        presets = {
          bottom_search = true,
          command_palette = true,
          long_message_to_split = true,
        },
      }

      -- If something opened a "lazy" buffer type, don't show the message backlog.
      if vim.o.filetype == "lazy" then
        vim.cmd([[messages clear]])
      end

      require("noice").setup(opts)
    end,
  },
}

