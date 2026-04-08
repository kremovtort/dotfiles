{ lib, ... }:
{
  plugins.treesitter = {
    enable = true;
    settings = {
      highlight.enable = lib.mkDefault true;
      indent.enable = lib.mkDefault true;
    };
  };

  plugins.treesitter-context = {
    enable = lib.mkDefault true;
    settings.on_attach.__raw = ''
      function(buf)
        return vim.bo[buf].buftype ~= "nofile"
      end
    '';
  };
 
  colorschemes.catppuccin.settings.integrations.treesitter_context.enable = lib.mkDefault true;

  plugins.ts-context-commentstring.enable = true;
}
