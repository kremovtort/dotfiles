{ lib, ... }:
{
  extraFiles = {
    "lua/tabterm/config.lua".source = ./tabterm/lua/tabterm/config.lua;
    "lua/tabterm/types.lua".source = ./tabterm/lua/tabterm/types.lua;
    "lua/tabterm/util.lua".source = ./tabterm/lua/tabterm/util.lua;
    "lua/tabterm/model.lua".source = ./tabterm/lua/tabterm/model.lua;
    "lua/tabterm/state.lua".source = ./tabterm/lua/tabterm/state.lua;
    "lua/tabterm/reducer.lua".source = ./tabterm/lua/tabterm/reducer.lua;
    "lua/tabterm/reconcile.lua".source = ./tabterm/lua/tabterm/reconcile.lua;
    "lua/tabterm/ui.lua".source = ./tabterm/lua/tabterm/ui.lua;
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
          width = 0.90,
          height = 0.90,
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
      key = "<C-/>";
      action.__raw = ''function() require("tabterm").toggle() end'';
      options.desc = "Toggle tab terminals";
    }
  ];
}
