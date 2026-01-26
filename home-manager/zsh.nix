{ pkgs, lib, ... }:
{
  home.packages = [
    (pkgs.writeShellScriptBin "lla-for-fzf" ''
      exa --color=always -la $(echo $1 | sed 's|^[^/]*/|/|')
    '')
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableVteIntegration = true;
    autocd = true;
    autosuggestion.enable = true;
    shellAliases = {
      "codenv" = "ya tool codenv";
      "cdi" = "zoxide query -a -i";
      "zi" = ''cd "$(zoxide query -a -i)"'';
      "zj" = "zellij";
    };
    plugins = [
      {
        name = "zsh-completions";
        src = pkgs.zsh-completions.src;
      }
      {
        name = "fast-syntax-highlighting";
        src = pkgs.zsh-fast-syntax-highlighting.src;
      }
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab.src;
      }
      {
        name = "zsh-vi-mode";
        src = pkgs.zsh-vi-mode.src;
      }
    ];
    initContent =
      let
        beforeZsh = lib.mkOrder 500 ''
          CATPUCCIN_COLORS_FZF="bg+:#2c2c2c,bg:#1c1c1c,spinner:#f5e0dc,hl:#f38ba8,fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc,marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8,selected-bg:#3c3c3c"

          export FZF_DEFAULT_OPTS=" \
            --color=$CATPUCCIN_COLORS_FZF \
            --multi --prompt='❯ ' --marker='+' --border=none"

          export _ZO_FZF_OPTS="--color=$CATPUCCIN_COLORS_FZF --reverse --preview='lla-for-fzf {}' --height=~50% --prompt='❯ ' --preview-border=line"

          # zsh-vi-mode overwrites keybindings after init, so we use its hook
          zvm_after_init_commands+=('bindkey "^r" _atuin_search_widget')

          # Ghostty encodes Ctrl-[ as CSI-u (fixterms), e.g. ^[[91;5u.
          # Without this binding, zsh may treat it as ESC + "...u" and run `u` (undo).
          zvm_after_init_commands+=('bindkey -M viins "^[[91;5u" vi-cmd-mode')
          zvm_after_init_commands+=('bindkey -M vicmd "^[[91;5u" vi-cmd-mode')
          zvm_after_init_commands+=('bindkey -M viins "^[[91;5:3u" vi-cmd-mode')
          zvm_after_init_commands+=('bindkey -M vicmd "^[[91;5:3u" vi-cmd-mode')
        '';
        # Ensure atuin keybinding is set after all other integrations (fzf, etc.)
        afterAll = lib.mkOrder 2000 ''
          bindkey '^r' _atuin_search_widget
        '';
      in
      lib.mkMerge [
        beforeZsh
        afterAll
      ];
  };
}
