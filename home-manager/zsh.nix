{ pkgs }:
{
  enable = true;
  enableCompletion = true;
  enableVteIntegration = true;
  autocd = true;
  autosuggestion.enable = true;
  shellAliases = {
    "codenv" = "ya tool codenv";
    "cdi" = "zoxide query -a -i";
    "zi" = ''cd "$(zoxide query -a -i)"'';
  };
  plugins = [
    { name = "zsh-completions"; src = pkgs.zsh-completions.src; }
    { name = "fast-syntax-highlighting"; src = pkgs.zsh-fast-syntax-highlighting.src; }
    { name = "fzf-tab"; src = pkgs.zsh-fzf-tab.src; }
  ];
  initContent = ''
    export FZF_DEFAULT_OPTS=" \
      --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
      --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
      --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
      --color=selected-bg:#45475a \
      --multi --prompt='❯ ' --marker='+'"
      
    export _ZO_FZF_OPTS="$FZF_DEFAULT_OPTS --layout=reverse --preview='lla-for-fzf {}'"
    
    bindkey '^k' 'cd "$(zoxide query -a -i)"'
  '';
}
