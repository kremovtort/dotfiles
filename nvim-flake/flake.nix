{
  description = "Neovim configuration flake (NixVim + Lua config)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Plugins not in nixpkgs
    plugins-opencode-nvim = {
      url = "github:sudo-tee/opencode.nvim";
      flake = false;
    };
  };

  outputs = inputs @ { self, nixpkgs, nixvim, ... }: {
    # Home-Manager module that builds wrapped Neovim via NixVim.
    homeModules.default = import ./module.nix { inherit inputs self; };
  };
}
