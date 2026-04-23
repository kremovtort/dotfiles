{ pkgs, ... }:
{
  extraPackages = [ pkgs.zoxide ];
  extraPlugins = [ pkgs.vimPlugins.zoxide-vim ];
}
