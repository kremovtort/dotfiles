{
  description = "Neovim configuration flake (nixCats + Lua config)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nixCats = {
      url = "github:BirdeeHub/nixCats-nvim";
    };

    plugins-opencode-nvim = {
      url = "github:sudo-tee/opencode.nvim";
      flake = false;
    };

    plugins-lze = {
      url = "github:BirdeeHub/lze";
      flake = false;
    };
  };

  outputs = inputs @ { self, ... }: {
    # Home-Manager module that builds wrapped Neovim via nixCats.
    homeManagerModules.default = import ./module.nix { inherit inputs self; };
  };
}

