{ ... }:
{
  plugins.edgy = {
    enable = false;
    autoLoad = true;
    settings = {
      animate.enabled = false;
      bottom.__raw = ''
        {
          {
            ft = "toggleterm",
            size = { height = 0.4 },
            wo = { winhighlight = "Normal:Normal,NormalNC:Normal", winblend = 0 },
            filter = function(_, win)
              return vim.api.nvim_win_get_config(win).relative == ""
            end,
          },
          {
            ft = "noice",
            size = { height = 0.4 },
            filter = function(_, win)
              return vim.api.nvim_win_get_config(win).relative == ""
            end,
          },
          "Trouble",
          { ft = "qf", title = "QuickFix" },
          {
            ft = "help",
            size = { height = 20 },
            filter = function(buf)
              return vim.bo[buf].buftype == "help"
            end,
          },
          { title = "Neotest Output", ft = "neotest-output-panel", size = { height = 15 } },
        }
      '';
      left.__raw = ''
        {
          { title = "Explorer", ft = "neo-tree" },
          { title = "Test Summary", ft = "neotest-summary" },
        }
      '';
      right.__raw = ''
        {
          { title = "Grug Far", ft = "grug-far", size = { width = 0.4 } },
          { 
            title = "Opencode",
            ft = "opencode_output",
            size = { width = 0.4 },
            wo = {
              winhighlight = "Normal:Normal,NormalNC:Normal",
              winblend = 0
            }
          },
          { 
            title = "Opencode",
            ft = "opencode",
            size = { width = 0.4, height = 8 },
            wo = {
              winhighlight = "Normal:Normal,NormalNC:Normal",
              winblend = 0
            }
          },
        }
      '';
      keys.__raw = ''
        {
          ["<c-Right>"] = function(win) win:resize("width", 2) end,
          ["<c-Left>"] = function(win) win:resize("width", -2) end,
          ["<c-Up>"] = function(win) win:resize("height", 2) end,
          ["<c-Down>"] = function(win) win:resize("height", -2) end,
        }
      '';
    };
    luaConfig.post = ''
      -- Add trouble and snacks_terminal windows dynamically
      local edgy_config = require("edgy.config")
      for _, pos in ipairs({ "top", "bottom", "left", "right" }) do
        edgy_config.options[pos] = edgy_config.options[pos] or {}
        -- trouble windows
        table.insert(edgy_config.options[pos], {
          ft = "trouble",
          filter = function(_, win)
            return vim.w[win].trouble
              and vim.w[win].trouble.position == pos
              and vim.w[win].trouble.type == "split"
              and vim.w[win].trouble.relative == "editor"
              and not vim.w[win].trouble_preview
          end,
        })
        -- snacks terminal windows
        table.insert(edgy_config.options[pos], {
          ft = "snacks_terminal",
          size = { height = 0.4 },
          title = "%{b:snacks_terminal.id}: %{b:term_title}",
          filter = function(_, win)
            return vim.w[win].snacks_win
              and vim.w[win].snacks_win.position == pos
              and vim.w[win].snacks_win.relative == "editor"
              and not vim.w[win].trouble_preview
          end,
        })
      end
    '';
  };

  keymaps = [
    {
      mode = "n";
      key = "<D-[>";
      action.__raw = "function() require('edgy').toggle('left') end";
      options.desc = "Toggle Left Panel";
    }
    {
      mode = "n";
      key = "<D-]>";
      action.__raw = "function() require('edgy').toggle('right') end";
      options.desc = "Toggle Right Panel";
    }
    {
      mode = "n";
      key = "<D-'>";
      action.__raw = "function() require('edgy').toggle('bottom') end";
      options.desc = "Toggle Bottom Panel";
    }
    {
      mode = [
        "n"
        "x"
        "o"
        "i"
      ];
      key = "<C-x><C-[>";
      action.__raw = ''
        function()
          local ok, edgy = pcall(require, "edgy")
          if ok then edgy.toggle("left") end
        end
      '';
      options.desc = "Toggle edgy.nvim (left)";
    }
    {
      mode = [
        "n"
        "x"
        "o"
        "i"
      ];
      key = "<C-x><C-]>";
      action.__raw = ''
        function()
          local ok, edgy = pcall(require, "edgy")
          if ok then edgy.toggle("right") end
        end
      '';
      options.desc = "Toggle edgy.nvim (right)";
    }
    {
      mode = [
        "n"
        "x"
        "o"
        "i"
      ];
      key = "<C-x><C-'>";
      action.__raw = ''
        function()
          local ok, edgy = pcall(require, "edgy")
          if ok then edgy.toggle("bottom") end
        end
      '';
      options.desc = "Toggle edgy.nvim (bottom)";
    }
  ];
}
