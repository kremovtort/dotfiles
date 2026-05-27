{
  pkgs,
  self,
  system,
  ...
}:
let
  isDarwin = system == "aarch64-darwin";
in
{
  home.file.".config/ghostty/themes/catppuccin-espresso".source =
    "${self}/catppuccin/ghostty-theme-catppuccin-espresso";

  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    package = if isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
    settings = {
      theme = "catppuccin-espresso";
      shell-integration-features = true;
      font-family = [
        "JetBrains Mono"
        "Symbols Nerd Font Mono"
      ];
      font-size = 12;
      adjust-icon-height = "-55%";
      macos-titlebar-style = "tabs";
      macos-option-as-alt = true;
      clipboard-read = "allow";
      clipboard-write = "allow";
      clipboard-paste-protection = false;
      window-padding-balance = true;
      window-padding-color = "extend";
      keybind = [
        "super+left_bracket=text:\\x1b[91;9u" # Cmd+[ -> <D-[>
        "super+right_bracket=text:\\x1b[93;9u" # Cmd+] -> <D-]>
        "super+apostrophe=text:\\x1b[39;9u" # Cmd+' -> <D-'>
      ];
    };
  };
}
