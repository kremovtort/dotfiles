{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "kremovtort";
  home.homeDirectory = "/home/kremovtort";
  
  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.

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
    
    # zsh
    pkgs.zsh-completions
    pkgs.zsh-fzf-tab
    pkgs.zsh-fast-syntax-highlighting
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    ".aider.conf.yml".source = ~/dotfiles/aider/.aider.conf.yml;
    ".aider.metadata.json".source = ~/dotfiles/aider/.aider.metadata.json;
    ".aider.model.settings.yml".source = ~/dotfiles/aider/.aider.model.settings.yml;
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/kremovtort/etc/profile.d/hm-session-vars.sh
  #
  home.shell.enableZshIntegration = true;

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
  ];
  
  i18n.glibcLocales = pkgs.glibcLocales.override {
    allLocales = false;
    locales = [
      "en_US.UTF-8/UTF-8"
      "ru_RU.UTF-8/UTF-8"
    ];
  };

  home.sessionVariables = {
    EDITOR = "code";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  
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
    envExtra = "
      source /etc/profile.d/nix-daemon.sh
    ";
    shellAliases = {
      hm = "home-manager";
    };
    
    initExtra = "
      source ${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh
      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
    ";
  };
  
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
  
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };
  
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };
  
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
  };
  
  programs.git = {
    enable = true;
    difftastic = {
      enable = true;
    };
    userName = "Alexander Makarov";
    userEmail = "i@kremovtort.ru";
  };
  
  programs.man = {
    enable = true;
  };
  
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    clock24 = true;
    customPaneNavigationAndResize = true;
    disableConfirmationPrompt = true;
    historyLimit = 10000;
    mouse = true;
    newSession = true;
    plugins = with pkgs; [
      tmuxPlugins.yank
      tmuxPlugins.prefix-highlight
      tmuxPlugins.better-mouse-mode
      tmuxPlugins.tmux-fzf
      tmuxPlugins.mode-indicator
      {
        plugin = tmuxPlugins.catppuccin;
        extraConfig = "set -g @catppuccin_flavor 'mocha'";
      }
    ];
    prefix = "C-Space";
    extraConfig = "set -g default-terminal 'tmux-256color'";
  };
}
