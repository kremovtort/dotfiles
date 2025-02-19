{ config, pkgs, ... }:

{
  home.username = "kremovtort";
  home.homeDirectory = "/home/kremovtort";
  programs.home-manager.enable = true;
  home.stateVersion = "24.11";

  home.packages = [
    pkgs.aider-chat
    pkgs.docker
    pkgs.lazydocker
    pkgs.lazygit
    pkgs.neovim
    pkgs.nil
    pkgs.ripgrep
    pkgs.pipx
    pkgs.uv
    pkgs.wezterm
    pkgs.zsh-completions
    pkgs.zsh-fzf-tab
    pkgs.zsh-fast-syntax-highlighting
  ];

  home.file = {
    ".aider.conf.yml".source = ~/dotfiles/aider/.aider.conf.yml;
    ".aider.model.metadata.json".source = ~/dotfiles/aider/.aider.model.metadata.json;
    ".aider.model.settings.yml".source = ~/dotfiles/aider/.aider.model.settings.yml;
    ".config/nvim/".source = ~/dotfiles/nvim;
    ".config/starship.toml".source = ~/dotfiles/starship.toml;
  };

  home.shell.enableZshIntegration = true;
  home.sessionPath = ["${config.home.homeDirectory}/.local/bin"];
  home.sessionVariables.EDITOR = "code";

  i18n.glibcLocales = pkgs.glibcLocales.override {
    allLocales = false;
    locales = ["en_US.UTF-8/UTF-8" "ru_RU.UTF-8/UTF-8"];
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
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

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
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
    terminal = "screen-256color";
    extraConfig = ''
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
    envExtra = "source /etc/profile.d/nix-daemon.sh";
    shellAliases = { hm = "home-manager"; };
    initExtra = ''
      source ${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh
      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
    '';
  };
}
