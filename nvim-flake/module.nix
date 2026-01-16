{ inputs, self, ... }:
let
  inherit (inputs.nixCats) utils;

  luaPath = "${self}/nvim";

  # Allows using flake inputs named `plugins-*` as `pkgs.neovimPlugins.<name>`.
  # We don't rely on this yet, but it keeps the door open for pinning plugins
  # not present in nixpkgs.
  dependencyOverlays = [
    (utils.standardPluginOverlay inputs)
  ];

  categoryDefinitions = { pkgs, ... }: {
    # Plugins loaded at startup (pack/*/start)
    startupPlugins = {
      core = [
        # We take lze from flake input `plugins-lze` via standardPluginOverlay.
        pkgs.neovimPlugins.lze
      ];
    };

    # Plugins installed as opt plugins (pack/*/opt). lze will `packadd` them.
    optionalPlugins = {
      core = with pkgs.vimPlugins; [
        catppuccin-nvim
      ];

      ui = with pkgs.vimPlugins; [
        nvim-scrollbar
        edgy-nvim
        snacks-nvim
        lualine-nvim
        mini-icons
        which-key-nvim
        blink-cmp
        blink-compat
        friendly-snippets
        noice-nvim
        nui-nvim
        nvim-notify
      ];

      editing = with pkgs.vimPlugins; [
        leap-nvim
        flit-nvim
        mini-pairs
        mini-ai
        mini-surround
        ts-comments-nvim
        grug-far-nvim
        vim-repeat
      ];

      vcs = with pkgs.vimPlugins; [
        hunk-nvim
      ];

      haskell = with pkgs.vimPlugins; [
        haskell-tools-nvim
      ];

      ai = [
        # Comes from flake input `plugins-opencode-nvim` via standardPluginOverlay.
        pkgs.neovimPlugins.opencode-nvim
        pkgs.vimPlugins.plenary-nvim
        pkgs.vimPlugins.render-markdown-nvim
        # render-markdown.nvim deps (see upstream README)
        pkgs.vimPlugins.nvim-treesitter
        pkgs.vimPlugins.mini-nvim
      ];
    };

    # Extra binaries and runtime deps available inside Neovim (added to PATH).
    lspsAndRuntimeDeps = {
      core = with pkgs; [
        ripgrep
        fd
        tree-sitter
      ];

      lsp = with pkgs; [
        lua-language-server
        nixd
        bash-language-server
      ];
    };
  };

  packageDefinitions = {
    nvim = { ... }: {
      settings = {
        wrapRc = true;
        configDirName = "nvim";
        aliases = [ "vi" "vim" ];
      };

      categories = {
        core = true;
        ui = true;
        editing = true;
        vcs = true;
        haskell = true;
        ai = true;
        lsp = true;
      };
    };
  };

  nixCatsHomeModule = utils.mkHomeModules {
    defaultPackageName = "nvim";
    moduleNamespace = [ "programs" "nvim" ];
    inherit luaPath dependencyOverlays categoryDefinitions packageDefinitions;
    nixpkgs = inputs.nixpkgs;
  };
in
{ config, ... }:
{
  imports = [
    nixCatsHomeModule
  ];

  programs.nvim.enable = true;

  home.file.".config/nvim/".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/nvim-flake/nvim";
}

