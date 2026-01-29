{ lib, ... }:
{
  plugins.treesitter = {
    enable = true;
    settings = {
      highlight.enable = lib.mkDefault true;
      indent.enable = lib.mkDefault true;
    };
  };
}
