{ pkgs, ... }:
{
  home.packages = [
    pkgs.jetbrains-mono
    pkgs.nerd-fonts.symbols-only
  ];

  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
    extraConfig = builtins.readFile ./wezterm/init.lua;
  };
}
