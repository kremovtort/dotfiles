{
  pkgs,
  lib,
  nvimInputs,
  ...
}:
let
  likec4Nvim = pkgs.vimUtils.buildVimPlugin {
    name = "likec4-nvim";
    src = nvimInputs.plugins-likec4-nvim;
  };
in
{
  extraPlugins = [ likec4Nvim ];

  extraConfigLua = lib.mkAfter ''
    vim.lsp.enable("likec4")
  '';
}
