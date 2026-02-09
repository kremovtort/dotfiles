{ lib, ... }:
{
  plugins.treesitter = {
    enable = true;
    settings = {
      highlight.enable = lib.mkDefault true;
      indent.enable = lib.mkDefault true;
    };
  };

  plugins.treesitter-context.enable = lib.mkDefault true;
  colorschemes.catppuccin.settings.integrations.treesitter_context.enable = lib.mkDefault true;

  plugins.ts-context-commentstring.enable = true;
}
