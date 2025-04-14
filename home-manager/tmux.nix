{ pkgs }:
{
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
    set-option -g renumber-windows on
    
    # Undercurl support
    set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'
    set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'

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
}