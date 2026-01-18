{
  config,
  pkgs,
  lib,
  system,
  flake-self,
  inputs,
  ...
}:
let
  isDarwin = system == "aarch64-darwin";
  userName = "Alexander Makarov";
  userEmail = "i@kremovtort.ru";
  darwinPkgs = map (lib.mkIf isDarwin) [
    pkgs.monitorcontrol
    pkgs.swiftdefaultapps
  ];
in
{
  imports = [
    inputs.skills.homeManagerModules.default
    ./karabiner.nix
    ./opencode.nix
    ./sops.nix
    ./tmux.nix
    ./zellij.nix
    ./zsh.nix
  ];

  home.username = "kremovtort";
  home.homeDirectory = if isDarwin then "/Users/kremovtort" else "/home/kremovtort";
  nixpkgs.config.allowUnfree = true;

  programs.home-manager.enable = true;
  home.stateVersion = "24.11";

  home.packages = [
    pkgs.ast-grep
    pkgs.bat
    pkgs.bash-language-server
    pkgs.bottom
    pkgs.devcontainer
    pkgs.docker
    pkgs.fd
    pkgs.gnumake
    pkgs.htop
    pkgs.kind
    pkgs.kubectl
    pkgs.kubernetes-helm
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.nixd
    pkgs.nixfmt
    pkgs.nodejs
    pkgs.nvim4vscode
    pkgs.openspec
    pkgs.ripgrep
    pkgs.shellcheck
    pkgs.tokei
    pkgs.tree-sitter
    pkgs.uv
    pkgs.zjstatus
    pkgs.zsh-completions
    pkgs.zsh-fast-syntax-highlighting
    pkgs.zsh-fzf-tab
    # for zoxide fzf preview
    (pkgs.writeShellScriptBin "lla-for-fzf" ''
      exa --color=always -la $(echo $1 | sed 's|^[^/]*/|/|')
    '')
    (pkgs.writeShellScriptBin "page" ''
      nvim +Man! "$@"
    '')
  ]
  ++ darwinPkgs;

  home.file = {
    ".clickhouse-client".source = "${flake-self}/clickhouse-client";
    ".config/starship.toml".source = "${flake-self}/starship.toml";
    ".config/ghostty/themes/catppuccin-espresso".source =
      "${flake-self}/catppuccin/ghostty-theme-catppuccin-espresso";
    ".config/opencode/themes/catppuccin-espresso.json".source =
      "${flake-self}/catppuccin/opencode-theme-catppuccin-espresso.json";
  };

  home.shell.enableZshIntegration = true;
  home.sessionPath = [
    "/opt/homebrew/bin"
    "${config.home.homeDirectory}/arcadia"
    "/codenv/arcadia"
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.rd/bin"
    "${config.home.homeDirectory}/.npm-globals/bin"
  ];
  home.sessionVariables.ARC = "${config.home.homeDirectory}/arcadia";
  home.sessionVariables.ARCADIA = "${config.home.homeDirectory}/arcadia";
  home.sessionVariables.SANDBOX_TOKEN = "\$(cat ~/.ya_token 2> /dev/null || true)";
  home.sessionVariables.DO_NOT_TRACK = "1";
  home.sessionVariables.LC_ALL = "en_US.UTF-8";
  home.sessionVariables.PAGER = "page";
  home.sessionVariables.MANPAGER = "page";

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      auto_sync = true;
      invert = true;
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    # Catppuccin Espresso palette (from `catppuccin/ghostty-theme-catppuccin-espresso`)
    options = {
      dark = true;
      navigate = true;

      # UI accents
      file-style = "bold #89b4fa";
      file-decoration-style = "none";
      # Ensure hunk headers show the starting line numbers (the @@ -a,b +c,d @@ part).
      hunk-header-style = "line-number syntax";
      hunk-header-file-style = "bold #89b4fa";
      hunk-header-line-number-style = "bold #bac2de";
      hunk-header-decoration-style = "#2c2c2c box";

      # Diff colors
      minus-style = "syntax #2a1f22";
      minus-emph-style = "syntax #3a232a";
      plus-style = "syntax #1f2a22";
      plus-emph-style = "syntax #25352a";
      zero-style = "syntax #1c1c1c";
      whitespace-error-style = "#f38ba8 reverse";

      # Syntax highlighting theme (provided by `bat --list-themes`)
      syntax-theme = "Catppuccin Mocha";
    };
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    config = {
      hide_env_diff = true;
    };
    nix-direnv.enable = true;
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    tmux.enableShellIntegration = true;
  };

  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    package = if isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
    settings = {
      theme = "catppuccin-espresso";
      shell-integration-features = true;
      font-family = "JetBrainsMono Nerd Font Mono";
      font-size = 12;
      macos-titlebar-style = "tabs";
      macos-option-as-alt = true;
      # Pass Cmd+[, Cmd+], Cmd+' to Neovim as <D-...> via CSI u protocol
      # Format: ESC [ keycode ; modifiers+1 u (Super=8, so 8+1=9)
      keybind = [
        "super+left_bracket=text:\\x1b[91;9u" # Cmd+[ -> <D-[>
        "super+right_bracket=text:\\x1b[93;9u" # Cmd+] -> <D-]>
        "super+apostrophe=text:\\x1b[39;9u" # Cmd+' -> <D-'>
      ];
    };
  };

  programs.git = {
    enable = true;
    settings.user.name = userName;
    settings.user.email = userEmail;
  };

  programs.jjui.enable = true;

  programs.jujutsu = {
    enable = true;
    settings.user.name = userName;
    settings.user.email = userEmail;
    settings.revsets.log = "present(@) | ancestors(@, 16) | ancestors(@.., 16)";
    settings.ui.diff-formatter = [
      "delta"
      "--paging=never"
      "$left"
      "$right"
    ];
    settings.ui.diff-editor = [
      "nvim"
      "-c"
      "DiffEditor $left $right $output"
    ];
  };

  programs.less.enable = true;
  programs.man.enable = true;

  programs.nix-your-shell = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.tealdeer.enable = true;

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
    extraConfig = builtins.readFile ../wezterm.lua;
  };
}
