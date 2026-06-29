{ pkgs, nvimInputs, ... }:
{
  extraPlugins = [
    (pkgs.vimUtils.buildVimPlugin {
      pname = "vim-herdr-navigation";
      version = "unstable-2026-06-29";

      src = nvimInputs.plugins-vim-herdr-navigation;

      # The editor side lives at editor/nvim.lua in the source tree, not under
      # plugin/. buildVimPlugin copies the tree as-is, so restructure in
      # preInstall into after/plugin/ to autoload last and win over any other
      # <C-h/j/k/l> mappings (per the plugin's README).
      preInstall = ''
        mkdir -p after/plugin
        cp editor/nvim.lua after/plugin/herdr-navigation.lua
      '';
    })
  ];
}
