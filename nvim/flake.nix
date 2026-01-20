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

    plugins-vcsigns-nvim = {
      url = "github:algmyr/vcsigns.nvim";
      flake = false;
    };

    plugins-vclib-nvim = {
      url = "github:algmyr/vclib.nvim";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixvim,
      ...
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      homeModules.default = import ./module.nix { inherit inputs self; };

      # Standalone packages
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          nixvim' = nixvim.legacyPackages.${system};
          # Build base nvim for vscode
          nvim4vscode-unwrapped = nixvim'.makeNixvimWithModule {
            inherit pkgs;
            module = import ./vscode.nix;
          };
        in
        {
          # Minimal Neovim for VSCode integration (renamed to avoid conflict)
          nvim4vscode = pkgs.runCommand "nvim4vscode" { } ''
            mkdir -p $out/bin
            ln -s ${nvim4vscode-unwrapped}/bin/nvim $out/bin/nvim4vscode
          '';
        }
      );
    };
}
