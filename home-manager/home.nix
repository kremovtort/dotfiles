{
  config,
  pkgs,
  lib,
  system,
  self,
  isLima,
  ...
}:
let
  isDarwin = system == "aarch64-darwin";
  userName = "Alexander Makarov";
  userEmail = "i@kremovtort.ru";
  darwinPkgs = map (lib.mkIf isDarwin) [
    pkgs.lima
    pkgs.monitorcontrol
    pkgs.swiftdefaultapps
  ];
in
{
  imports = [
    ./karabiner.nix
    ./sops.nix
    ./tmux.nix
    # ./zellij.nix
    ./zsh.nix
    ./starship.nix
  ];

  home.username = "kremovtort";
  home.homeDirectory =
    if isDarwin then
      "/Users/kremovtort"
    else if isLima then
      "/home/kremovtort.linux"
    else
      "/home/kremovtort";
  nixpkgs.config.allowUnfree = true;

  programs.home-manager.enable = true;
  home.stateVersion = "24.11";

  home.packages = [
    pkgs.ast-grep
    (pkgs.writeShellScriptBin "sg" ''
      ast-grep $@
    '')
    pkgs.bat
    pkgs.bash-language-server
    pkgs.bottom
    pkgs.bun
    pkgs.devcontainer
    pkgs.docker
    pkgs.fd
    pkgs.gnumake
    pkgs.htop
    pkgs.jiq
    pkgs.jless
    pkgs.jq
    pkgs.kind
    pkgs.kubectl
    pkgs.kubernetes-helm
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.nixd
    pkgs.nixfmt
    pkgs.nodejs
    pkgs.nvim
    pkgs.nvim4vscode
    pkgs.ov
    pkgs.ripgrep
    pkgs.shellcheck
    pkgs.tokei
    pkgs.tree-sitter
    pkgs.uv
    pkgs.zsh-completions
    pkgs.zsh-fast-syntax-highlighting
    pkgs.zsh-fzf-tab
  ]
  ++ darwinPkgs;

  home.file = {
    ".clickhouse-client".source = "${self}/clickhouse-client";
    ".config/ghostty/themes/catppuccin-espresso".source =
      "${self}/catppuccin/ghostty-theme-catppuccin-espresso";
    ".config/opencode/themes/catppuccin-espresso.json".source =
      "${self}/catppuccin/opencode-theme-catppuccin-espresso.json";
    ".config/ov/config.yaml".source = "${self}/ov.yaml";
  };

  home.shell.enableZshIntegration = true;
  home.sessionPath = [
    "/opt/homebrew/bin"
    "/a"
    "/codenv/arcadia"
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.rd/bin"
    "${config.home.homeDirectory}/.npm-globals/bin"
    "${config.home.homeDirectory}/.bun/bin"
  ];
  home.sessionVariables.ARC = "/a";
  home.sessionVariables.ARCADIA = "/a";
  home.sessionVariables.EDITOR = "nvim";
  home.sessionVariables.VISUAL = "nvim";
  home.sessionVariables.SANDBOX_TOKEN = "\$(cat ~/.ya_token 2> /dev/null || true)";
  home.sessionVariables.DO_NOT_TRACK = "1";
  home.sessionVariables.LC_ALL = "en_US.UTF-8";
  home.sessionVariables.PAGER = "ov";
  home.sessionVariables.MANPAGER = "ov";

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
    enableJujutsuIntegration = true;
    # Catppuccin Espresso palette (from `catppuccin/ghostty-theme-catppuccin-espresso`)
    options = {
      dark = true;
      navigate = true;

      # UI accents
      file-style = "bold #89b4fa";
      file-decoration-style = "none";
      # Ensure hunk headers show the starting line numbers (the @@ -a,b +c,d @@ part).
      # hunk-header-style = "line-number syntax";
      # hunk-header-file-style = "bold #89b4fa";
      # hunk-header-line-number-style = "bold #bac2de";
      # hunk-header-decoration-style = "#2c2c2c box";

      # Diff colors
      minus-style = "syntax #2a1f22";
      minus-emph-style = "syntax #3a232a";
      plus-style = "syntax #1f2a22";
      plus-emph-style = "syntax #25352a";
      # NOTE: delta 0.18.2 on nixpkgs currently panics when `zero-style`
      # is given a background color ("capacity overflow"), which breaks jjui
      # and any git/jj pager output. Keep it background-free.
      zero-style = "syntax";
      whitespace-error-style = "#f38ba8 reverse";
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
      clipboard-read = "allow";
      clipboard-write = "allow";
      clipboard-paste-protection = false;
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

  programs.jjui = {
    enable = true;
    settings = {
      preview = {
        revision_command = [
          "util"
          "exec"
          "--"
          "bash"
          "-c"
          "jj show --git -r $change_id | delta --paging never"
        ];
        file_command = [
          "util"
          "exec"
          "--"
          "bash"
          "-c"
          "jj diff --git -r $change_id $file | delta --paging never"
        ];
      };
    };
  };

  programs.jujutsu = {
    enable = true;
    settings.user.name = userName;
    settings.user.email = userEmail;
    settings.revsets.log = "present(@) | ancestors(@, 16) | ancestors(@.., 16)";
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
