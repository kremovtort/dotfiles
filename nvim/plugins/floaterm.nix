{
  pkgs,
  lib,
  nvimInputs,
  ...
}:
let
  volt = pkgs.vimUtils.buildVimPlugin {
    name = "volt";
    src = nvimInputs.plugins-volt;
  };
  floaterm = pkgs.vimUtils.buildVimPlugin {
    name = "floaterm";
    src = nvimInputs.plugins-floaterm;
    dependencies = [ volt ];
  };
in {
  extraPlugins = [ floaterm ];

  extraConfigLua = lib.mkAfter ''
    require("floaterm").setup({
      border = false,
      size = { h = 60, w = 70 },

      -- to use, make this func(buf)
      mappings = { sidebar = nil, term = nil},

      -- Default sets of terminals you'd like to open
      terminals = {
        { name = "Terminal" },
      },
    })
  '';
}
