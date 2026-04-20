{
  pkgs,
  lib,
  system,
  ...
}:
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
      "vi" = "nvim";
      "vim" = "nvim";
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
        darwinUlimit = lib.mkIf (system == "aarch64-darwin") (
          lib.mkOrder 1 ''
            ulimit -Sn 8192
          ''
        );

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

          autoload -Uz add-zsh-hook

          typeset -g TABTERM_SHELL_COMMAND_ACTIVE=0

          _tabterm_emit_osc7() {
            printf '\033]7;file://%s%s\033\\' "$HOST" "$PWD"
          }

          _tabterm_set_title() {
            printf '\033]2;%s\033\\' "$1"
          }

          _tabterm_command_label() {
            local input="$1"
            local -a words
            local word
            local index=1
            local shell_name
            local result=""
            local first=1

            words=(''${(z)input})
            shell_name=$(basename -- "''${SHELL:-zsh}")

            while (( index <= $#words )); do
              word="''${words[index]}"

              if [[ "$word" == *=* && "$word" != */* ]]; then
                (( index++ ))
                continue
              fi

              case "$word" in
                command|builtin|noglob|nocorrect|nohup|time)
                  (( index++ ))
                  continue
                  ;;
                env)
                  (( index++ ))
                  while (( index <= $#words )); do
                    word="''${words[index]}"
                    if [[ "$word" == -* ]]; then
                      (( index++ ))
                      continue
                    fi
                    if [[ "$word" == *=* && "$word" != */* ]]; then
                      (( index++ ))
                      continue
                    fi
                    break
                  done
                  continue
                  ;;
                sudo|doas|nice)
                  (( index++ ))
                  while (( index <= $#words )); do
                    word="''${words[index]}"
                    if [[ "$word" == -* ]]; then
                      (( index++ ))
                      continue
                    fi
                    if [[ "$word" == *=* && "$word" != */* ]]; then
                      (( index++ ))
                      continue
                    fi
                    break
                  done
                  continue
                  ;;
              esac

              break
            done

            while (( index <= $#words )); do
              word="''${words[index]}"
              if (( first )) && [[ "$word" == */* ]]; then
                word=$(basename -- "$word")
              fi

              if [[ -n "$result" ]]; then
                result="$result $word"
              else
                result="$word"
              fi

              first=0
              (( index++ ))
            done

            if [[ -n "$result" ]]; then
              print -r -- "$result"
              return
            fi

            print -r -- "$shell_name"
          }

          _tabterm_precmd() {
            local exit_code=$?
            local shell_name
            shell_name=$(basename -- "''${SHELL:-zsh}")
            if (( TABTERM_SHELL_COMMAND_ACTIVE )); then
              printf '\033]133;D;%s\033\\' "$exit_code"
              TABTERM_SHELL_COMMAND_ACTIVE=0
            fi
            _tabterm_set_title "$shell_name"
            printf '\033]133;A\033\\'
            _tabterm_emit_osc7
          }

          _tabterm_preexec() {
            TABTERM_SHELL_COMMAND_ACTIVE=1
            _tabterm_set_title "$(_tabterm_command_label "$1")"
            printf '\033]133;B\033\\'
            printf '\033]133;C\033\\'
          }

          add-zsh-hook precmd _tabterm_precmd
          add-zsh-hook preexec _tabterm_preexec
        '';
        # Ensure atuin keybinding is set after all other integrations (fzf, etc.)
        afterAll = lib.mkOrder 2000 ''
          bindkey '^r' _atuin_search_widget
        '';
      in
      lib.mkMerge [
        darwinUlimit
        beforeZsh
        afterAll
      ];
  };
}
