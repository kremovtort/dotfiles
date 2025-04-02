{ config, pkgs, lib, system, ... }:
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
    pkgs.bottom
    pkgs.docker
    pkgs.gnumake
    pkgs.neovim
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.nil
    pkgs.ripgrep
    pkgs.shellcheck
    pkgs.zsh-completions
    pkgs.zsh-fast-syntax-highlighting
    pkgs.zsh-fzf-tab

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
    ".config/nvim/".source = ../lazyvim;
    ".config/starship.toml".source = ../starship.toml;
  };

  home.shell.enableZshIntegration = true;
  home.sessionPath = [
    "/opt/homebrew/bin"
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/arcadia"
    "/codenv/arcadia"
  ];
  home.sessionVariables.EDITOR = "code";
  home.sessionVariables.arc = "~/arcadia";
  home.sessionVariables.arcadia = "~/arcadia";

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv = {
      enable = true;
    };
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

  programs.less = {
    enable = true;
  };

  programs.man = {
    enable = true;
  };

  programs.nix-your-shell = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.tealdeer = {
    enable = true;
  };

  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
    extraConfig = builtins.readFile ../wezterm.lua;
  };

  programs.tmux = {
    enable = true;
    baseIndex = 1;
    clock24 = true;
    customPaneNavigationAndResize = true;
    disableConfirmationPrompt = true;
    historyLimit = 50000;
    keyMode = "vi";
    mouse = true;
    newSession = true;
    plugins = with pkgs; [
      tmuxPlugins.yank
      tmuxPlugins.better-mouse-mode
      tmuxPlugins.mode-indicator
      {
        plugin = tmuxPlugins.tmux-fzf;
        extraConfig = "TMUX_FZF_OPTIONS=\"-p -w 70% -h 70% -m\"";
      }
      {
        plugin = tmuxPlugins.catppuccin;
        extraConfig = "set -g @catppuccin_flavor 'mocha'";
      }
    ];
    prefix = "C-Space";
    terminal = "tmux-256color";
    extraConfig = ''
      set-option -g renumber-windows on

      unbind '%'
      unbind '"'
      bind '-' split-window
      bind '|' split-window -h

      set-window-option -g mode-keys vi
      bind-key -T copy-mode-vi v send -X begin-selection
      bind-key -T copy-mode-vi V send -X select-line
      bind-key -T copy-mode-vi y send -X copy-selection
      bind-key -T copy-mode-vi i send-keys -X cancel
      bind-key -T copy-mode-vi a send-keys -X cancel
    '';
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableVteIntegration = true;
    autocd = true;
    autosuggestion.enable = true;
    shellAliases = {
      "codenv" = "ya tool codenv";
    };
    plugins = [
      { name = "zsh-completions"; src = pkgs.zsh-completions.src; }
      { name = "fast-syntax-highlighting"; src = pkgs.zsh-fast-syntax-highlighting.src; }
      { name = "fzf-tab"; src = pkgs.zsh-fzf-tab.src; }
    ];
    initExtra = ''
      export FZF_DEFAULT_OPTS=" \
        --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
        --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
        --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
        --color=selected-bg:#45475a \
        --multi --prompt='❯ ' --marker='+'"
    '';
  };
}
