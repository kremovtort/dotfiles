{ ... }:
{
  imports = [
    ./plugins/scrollbar.nix
    ./plugins/vcsigns.nix

    ./plugins/auto-save.nix
    ./plugins/origami.nix
    ./plugins/treesitter.nix
    ./plugins/lsp.nix
    ./plugins/supermaven.nix
    ./plugins/blink-cmp.nix
    ./plugins/which-key.nix
    ./plugins/noice.nix
    ./plugins/notify.nix

    ./plugins/trouble.nix

    ./plugins/overseer.nix

    ./plugins/icons.nix
    ./plugins/mini-pairs.nix
    ./plugins/mini-ai.nix
    ./plugins/mini-diff.nix
    ./plugins/mini-surround.nix

    ./plugins/leap.nix
    ./plugins/hunk.nix
    ./plugins/ts-context-commentstring.nix
    ./plugins/grug-far.nix
    ./plugins/snacks.nix
    ./plugins/seeker.nix
    ./plugins/render-markdown.nix

    ./plugins/haskell.nix

    # ./plugins/edgy.nix
    # ./plugins/neo-tree.nix
    ./plugins/toggleterm.nix

    ./plugins/repeat.nix
    ./plugins/auto-session.nix
    ./plugins/yanky.nix

    ./plugins/langmapper.nix
    ./plugins/lualine.nix
    ./plugins/tabby.nix

    ./plugins/nvim-bqf.nix

    ./plugins/opencode/provider-nickvandyke.nix
  ];
}
