{ pkgs, lib, ... }:
{
  extraPlugins = [ pkgs.vimPlugins.nvim-scrollbar ];

  extraConfigLua = lib.mkAfter ''
    require("scrollbar").setup({
      excluded_filetypes = { 
        "tabterm-sidebar",
      }
    })
  '';
}
