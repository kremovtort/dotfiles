{ pkgs, lib, system, catppuccin-ghostty, ... }:
let
  isDarwin = system == "aarch64-darwin";
in {
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
    pkgs.docker
    pkgs.fd
    pkgs.gnumake
    pkgs.goose-cli
    pkgs.kind
    pkgs.kubectl
    pkgs.kubernetes-helm
    pkgs.neovim
    pkgs.nvimpager
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.nil
    pkgs.ripgrep
    pkgs.shellcheck
    pkgs.uv
    pkgs.zsh-completions
    pkgs.zsh-fast-syntax-highlighting
    pkgs.zsh-fzf-tab
    (pkgs.writeShellScriptBin "nvim-pager" ''
      ${pkgs.neovim}/bin/nvim -c "Man! $@"
    '')

    (lib.mkIf isDarwin pkgs.colima)
    (lib.mkIf isDarwin pkgs.podman)
    (lib.mkIf isDarwin pkgs.alt-tab-macos)
    (lib.mkIf isDarwin pkgs.ice-bar)
    (lib.mkIf isDarwin pkgs.maccy)
    (lib.mkIf isDarwin pkgs.monitorcontrol)
    (lib.mkIf isDarwin pkgs.swiftdefaultapps)
  ];

  home.file = {
    ".aider.conf.yml".source = ../aider/.aider.conf.yml;
    ".aider.model.metadata.json".source = ../aider/.aider.model.metadata.json;
    ".aider.model.settings.yml".source = ../aider/.aider.model.settings.yml;
    ".clickhouse-client".source = ../clickhouse-client;
    ".config/nvim/".source = ../lazyvim;
    ".config/starship.toml".source = ../starship.toml;
    ".config/ghostty/config".text = ''
      theme = catppuccin-mocha.conf
      font-family = JetBrainsMono Nerd Font Mono
    '';
    ".config/ghostty/themes/catppuccin-mocha.conf".source = "${catppuccin-ghostty}/themes/catppuccin-mocha.conf";
  };

  home.shell.enableZshIntegration = true;
  home.sessionPath = [
    "/opt/homebrew/bin"
    "\${HOME}/arcadia"
    "/codenv/arcadia"
    "\${HOME}/.local/bin"
  ];
  home.sessionVariables.EDITOR = "code";
  home.sessionVariables.ARC = "\${HOME}/arcadia";
  home.sessionVariables.ARCADIA = "\${HOME}/arcadia";
  home.sessionVariables.SANDBOX_TOKEN = "\$(cat ~/.ya_token 2> /dev/null || true)";
  home.sessionVariables.LC_ALL = "en_US.UTF-8";
  home.sessionVariables.PAGER = "nvim +Man!";
  home.sessionVariables.MANPAGER = "nvim +Man!";

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
  
  programs.git = {
    enable = true;
    difftastic.enable = true;
    userName = "Alexander Makarov";
    userEmail = "i@kremovtort.ru";
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

  programs.zsh = import ./zsh.nix { inherit pkgs; };
}
