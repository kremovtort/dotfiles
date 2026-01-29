# OpenCode integration via sudo-tee/opencode.nvim (Neovim UI frontend).
# This is built from the flake input `plugins-opencode-nvim`.
{ pkgs, nvimInputs, ... }:
let
  opencodeNvim = pkgs.vimUtils.buildVimPlugin {
    name = "opencode-nvim";
    src = nvimInputs.plugins-opencode-nvim;
    dependencies = with pkgs.vimPlugins; [
      plenary-nvim
      nui-nvim
    ];
  };
in
{
  extraPlugins = [ opencodeNvim ];

  extraConfigLua = ''
    require("opencode").setup({
      preferred_picker = "snacks",
      preferred_completion = "blink",

      default_global_keymaps = true,
      keymap_prefix = "<leader>a",
    })
  '';
}
