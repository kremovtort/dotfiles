return {
  -- Provide snippets (runtime files). Load it automatically when blink-cmp loads.
  {
    -- packadd name must match nixCats opt dir (`friendly-snippets`).
    "friendly-snippets",
    dep_of = { "blink.cmp" },
  },

  -- Optional compat layer for nvim-cmp sources.
  {
    -- packadd name must match nixCats opt dir (`blink.compat`).
    "blink.compat",
    on_require = { "blink.compat", "blink.compat.source" },
  },

  {
    -- packadd name must match nixCats opt dir (`blink.cmp`).
    "blink.cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    after = function()
      local icons = require("config.icons")

      ---@type table
      local opts = {
        snippets = {
          preset = "default",
          expand = function(args)
            -- Neovim 0.10+ built-in snippets.
            vim.snippet.expand(args.body)
          end,
        },

        appearance = {
          use_nvim_cmp_as_default = false,
          nerd_font_variant = "mono",
          kind_icons = icons.kinds,
        },

        completion = {
          accept = {
            auto_brackets = { enabled = true },
          },
          menu = {
            draw = {
              treesitter = { "lsp" },
            },
          },
          documentation = {
            auto_show = true,
            auto_show_delay_ms = 200,
          },
          ghost_text = {
            enabled = vim.g.ai_cmp,
          },
        },

        sources = {
          -- Adding any nvim-cmp sources here will enable them with blink.compat.
          compat = {},
          default = { "lsp", "path", "snippets", "buffer" },
          providers = {},
        },

        cmdline = {
          enabled = true,
          keymap = {
            preset = "cmdline",
            ["<Right>"] = false,
            ["<Left>"] = false,
          },
          completion = {
            list = { selection = { preselect = false } },
            menu = {
              auto_show = function()
                return vim.fn.getcmdtype() == ":"
              end,
            },
            ghost_text = { enabled = true },
          },
        },

        keymap = {
          preset = "enter",
          ["<C-y>"] = { "select_and_accept" },
        },
      }

      -- Setup compat sources (merged from LazyVim config, without LazyVim helpers).
      local enabled = opts.sources.default
      for _, source in ipairs(opts.sources.compat or {}) do
        opts.sources.providers[source] = vim.tbl_deep_extend(
          "force",
          { name = source, module = "blink.compat.source" },
          opts.sources.providers[source] or {}
        )
        if type(enabled) == "table" and not vim.tbl_contains(enabled, source) then
          table.insert(enabled, source)
        end
      end
      opts.sources.compat = nil

      require("blink.cmp").setup(opts)
    end,
  },
}

