{ config, pkgs, ... }:

{
  home.username = "kremovtort";
  home.homeDirectory = "/home/kremovtort";
  home.stateVersion = "24.11";
  programs.home-manager.enable = true;

  home.packages = [
    pkgs.aider-chat
    pkgs.docker
    pkgs.gcc
    pkgs.gnumake
    pkgs.just
    pkgs.lazydocker
    pkgs.lazygit
    pkgs.neovim
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.nil
    pkgs.ripgrep
    pkgs.pipx
    pkgs.python3
    pkgs.shellcheck
    pkgs.vscode-fhs
    pkgs.wezterm
    pkgs.zsh-completions
    pkgs.zsh-fast-syntax-highlighting
    pkgs.zsh-fzf-tab
  ];

  home.file = {
    ".aider.conf.yml".source = ../aider/.aider.conf.yml;
    ".aider.model.metadata.json".source = ../aider/.aider.model.metadata.json;
    ".aider.model.settings.yml".source = ../aider/.aider.model.settings.yml;
    ".wezterm.lua".source = ../.wezterm.lua;
    ".config/nvim/".source = ../nvim;
    ".config/starship.toml".source = ../starship.toml;
  };

  home.shell.enableZshIntegration = true;
  home.sessionPath = ["${config.home.homeDirectory}/.local/bin"];
  home.sessionVariables.EDITOR = "code";
  home.sessionVariables.XDG_DATA_DIRS = builtins.concatStringsSep ":" [
    "$XDG_DATA_DIRS"
    "/usr/share"
    "/var/lib/flatpak/exports/share"
    "$HOME/.local/share/flatpak/exports/share"
  ];

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
      hm = "home-manager";
      hms = "home-manager switch --flake ${config.home.homeDirectory}/dotfiles";
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
