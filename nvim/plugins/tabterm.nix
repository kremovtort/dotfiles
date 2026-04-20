{ lib, ... }:
{
  extraFiles = {
    "lua/tabterm/config.lua".source = ./tabterm/lua/tabterm/config.lua;
    "lua/tabterm/types.lua".source = ./tabterm/lua/tabterm/types.lua;
    "lua/tabterm/model.lua".source = ./tabterm/lua/tabterm/model.lua;
    "lua/tabterm/state.lua".source = ./tabterm/lua/tabterm/state.lua;
    "lua/tabterm/reducer.lua".source = ./tabterm/lua/tabterm/reducer.lua;
    "lua/tabterm/reconcile.lua".source = ./tabterm/lua/tabterm/reconcile.lua;
    "lua/tabterm/ui.lua".source = ./tabterm/lua/tabterm/ui.lua;
    "lua/tabterm/persistence.lua".source = ./tabterm/lua/tabterm/persistence.lua;
    "lua/tabterm/events.lua".source = ./tabterm/lua/tabterm/events.lua;
    "lua/tabterm/init.lua".source = ./tabterm/lua/tabterm/init.lua;
    "plugin/tabterm.lua".source = ./tabterm/plugin/tabterm.lua;
  };

  extraConfigLua = lib.mkAfter ''
    require("tabterm").setup({
      ui = {
        border = "rounded",
        sidebar_width = 30,
        float = {
          width = 0.70,
          height = 0.70,
        },
      },
    })
  '';

  keymaps = [
    {
      mode = [
        "n"
        "t"
      ];
      key = "<D-j>";
      action.__raw = ''function() require("tabterm").toggle() end'';
      options.desc = "Toggle tab terminals";
    }
    {
      mode = "n";
      key = "<leader>tt";
      action.__raw = ''function() require("tabterm").toggle() end'';
      options.desc = "Toggle tab terminals";
    }
    {
      mode = "n";
      key = "<leader>tn";
      action.__raw = ''function() require("tabterm").new_shell() end'';
      options.desc = "New tab shell";
    }
    {
      mode = "n";
      key = "<leader>tc";
      action.__raw = ''function() require("tabterm").new_command() end'';
      options.desc = "New tab command";
    }
    {
      mode = [
        "n"
        "t"
      ];
      key = "]t";
      action.__raw = ''function() require("tabterm").next_terminal() end'';
      options.desc = "Next tab terminal";
    }
    {
      mode = [
        "n"
        "t"
      ];
      key = "[t";
      action.__raw = ''function() require("tabterm").prev_terminal() end'';
      options.desc = "Previous tab terminal";
    }
  ];
}
