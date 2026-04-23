{
  pkgs,
  lib,
  nvimInputs,
  ...
}:
let
  direnvNvim = pkgs.vimUtils.buildVimPlugin {
    name = "direnv-nvim";
    src = nvimInputs.plugins-direnv-nvim;
  };
in
{
  extraPlugins = [ direnvNvim ];

  extraConfigLua = lib.mkAfter ''
    require("direnv").setup({
      autoload_direnv = true,
      statusline = {
        enabled = true,
      },
      keybindings = false,
      notifications = {
        silent_autoload = true,
      },
    })
  '';
}
