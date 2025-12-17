{ pkgs, lib, system, flake-self, inputs, ... }:
let
  isDarwin = system == "aarch64-darwin";
  userName = "Alexander Makarov";
  userEmail = "i@kremovtort.ru";
  darwinPkgs = map (lib.mkIf isDarwin) [
    pkgs.alt-tab-macos
    pkgs.ice-bar
    pkgs.monitorcontrol
    pkgs.swiftdefaultapps
    inputs.paneru.packages.${system}.paneru
  ];
in {
  imports = [
    ./karabiner.nix
  ];

  home.username = "kremovtort";
  home.homeDirectory = if isDarwin
    then "/Users/kremovtort"
    else "/home/kremovtort";
  nixpkgs.config.allowUnfree = true;

  programs.home-manager.enable = true;
  home.stateVersion = "24.11";

  home.packages = [
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
    pkgs.neovim
    pkgs.nvimpager
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.nixd
    pkgs.nodejs
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
  ] ++ darwinPkgs;

  home.file = {
    ".clickhouse-client".source = "${flake-self}/clickhouse-client";
    ".config/nvim/" = {
      source = "${flake-self}/nvim";
      recursive = true;
    };
    ".config/starship.toml".source = "${flake-self}/starship.toml";
  };

  home.shell.enableZshIntegration = true;
  home.sessionPath = [
    "/opt/homebrew/bin"
    "\${HOME}/arcadia"
    "/codenv/arcadia"
    "\${HOME}/.local/bin"
    "\${HOME}/.rd/bin"
  ];
  home.sessionVariables.EDITOR = "nvim";
  home.sessionVariables.ARC = "\${HOME}/arcadia";
  home.sessionVariables.ARCADIA = "\${HOME}/arcadia";
  home.sessionVariables.SANDBOX_TOKEN = "\$(cat ~/.ya_token 2> /dev/null || true)";
  home.sessionVariables.LC_ALL = "en_US.UTF-8";
  home.sessionVariables.PAGER = "nvimpager";
  home.sessionVariables.MANPAGER = "nvimpager";

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
      theme = "Catppuccin Mocha";
      shell-integration-features = true;
      font-family = "JetBrainsMono Nerd Font Mono";
      font-size = 12;
      macos-titlebar-style = "tabs";
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
    settings.ui.diff-editor = ["nvim" "-c" "DiffEditor $left $right $output"];
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

  programs.tmux = import ./tmux.nix { inherit pkgs; };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = import ./zsh.nix { inherit pkgs lib; };
  
  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
    extraConfig = builtins.readFile ../wezterm.lua;
  };

  programs.zellij = import ./zellij.nix { inherit pkgs; };

  services.paneru = lib.mkIf isDarwin (import ./paneru.nix {});
}
