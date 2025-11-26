{ pkgs, lib, system, flake-self, ... }:
let
  isDarwin = system == "aarch64-darwin";
  darwinPkgs = map (lib.mkIf isDarwin) [
    pkgs.alt-tab-macos
    pkgs.ice-bar
    pkgs.maccy
    pkgs.monitorcontrol
    pkgs.swiftdefaultapps
  ];
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
    pkgs.devcontainer
    pkgs.docker
    pkgs.fd
    pkgs.gnumake
    pkgs.htop
    pkgs.jjui
    pkgs.jujutsu
    pkgs.kind
    pkgs.kubectl
    pkgs.kubernetes-helm
    pkgs.neovim
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.nixd
    pkgs.nodejs
    pkgs.ripgrep
    pkgs.shellcheck
    pkgs.tokei
    pkgs.tree-sitter
    pkgs.uv
    pkgs.zsh-completions
    pkgs.zsh-fast-syntax-highlighting
    pkgs.zsh-fzf-tab
    (pkgs.writeShellScriptBin "nvim-pager" ''
      ${pkgs.neovim}/bin/nvim -c "Man! $@"
    '')
    # for zoxide fzf preview
    (pkgs.writeShellScriptBin "lla-for-fzf" ''
      exa --color=always -la $(echo $1 | sed 's|^[^/]*/|/|')
    '')
  ] ++ darwinPkgs;

  home.file = {
    ".clickhouse-client".source = "${flake-self}/clickhouse-client";
    ".config/nvim/".source = "${flake-self}/nvim";
    ".config/starship.toml".source = "${flake-self}/starship.toml";
    ".config/jj/config.toml".text = ''
      "$schema" = "https://jj-vcs.github.io/jj/latest/config-schema.json"

      [user]
      name = "Alexander Makarov"
      email = "i@kremovtort.ru"
    '';
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
  home.sessionVariables.PAGER = "nvim +Man!";
  home.sessionVariables.MANPAGER = "nvim +Man!";

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      auto_sync = true;
    };
  };
  
  programs.difftastic.enable = true;

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
    settings.user.name = "Alexander Makarov";
    settings.user.email = "i@kremovtort.ru";
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
  
  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
    extraConfig = builtins.readFile ../wezterm.lua;
  };

  services.paneru = lib.mkIf isDarwin {
    enable = true;
    # Equivalent to what you would put into `~/.paneru` (See Configuration options below).
    settings = {
      options = {
        focus_follows_mouse = true;
        preset_column_widths = [
          0.25
          0.33
          0.5
          0.66
          0.75
          1
        ];
        swipe_gesture_fingers = 3;
        animation_speed = 10000;
      };
      bindings = {
        window_focus_west = "cmd + ctrl - h";
        window_focus_east = "cmd + ctrl - l";
        window_focus_north = "cmd + ctrl - k";
        window_focus_south = "cmd + ctrl - j";
        window_swap_west = "alt + ctrl - h";
        window_swap_east = "alt + ctrl - l";
        window_swap_first = "alt + shift - h";
        window_swap_last = "alt + shift - l";
        window_center = "alt - c";
        window_resize = "alt - r";
        window_manage = "cmd + alt - t";
        window_stack = "alt + ctrl - ]";
        window_unstack = "alt + ctrl + shift - ]";
        quit = "ctrl + alt - q";
      };
    };
  };
}
