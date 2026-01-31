{ pkgs, lib, ... }:
{
  extraPlugins = [ pkgs.vimPlugins.tabby-nvim ];

  extraConfigLua = lib.mkAfter ''
    require("tabby").setup({
      preset = "active_tab_with_wins",
    })
  '';
}
