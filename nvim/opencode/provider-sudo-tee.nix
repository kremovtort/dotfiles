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
  programs.nixvim = {
    extraPlugins = [ opencodeNvim ];

    # Configure the plugin.
    extraConfigLua = ''
      -- Keep opencode.nvim settings in a single place.
      -- We disable its default global keymaps and use our own (<leader>a...).
      require("opencode").setup({
        preferred_picker = "snacks",
        preferred_completion = "blink",

        default_global_keymaps = false,
        keymap_prefix = "<leader>a",
      })
    '';
  };
}
