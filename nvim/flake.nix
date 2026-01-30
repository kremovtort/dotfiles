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

    plugins-virtual-types-nvim = {
      url = "github:jubnzv/virtual-types.nvim";
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
      lib = {
        mkNvim =
          {
            system,
            pkgs ? nixpkgs.legacyPackages.${system},
            extraModules ? [ ],
            extraSpecialArgs ? { },
          }:
          let
            nixvim' = nixvim.legacyPackages.${system};
          in
          nixvim'.makeNixvimWithModule {
            inherit pkgs;
            module = {
              imports = [
                ./config.nix
                ./plugins.nix
              ]
              ++ extraModules;
            };
            extraSpecialArgs = {
              nvimInputs = inputs;
            }
            // extraSpecialArgs;
          };
      };

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          nixvim' = nixvim.legacyPackages.${system};

          nvim-unwrapped = self.lib.mkNvim { inherit system pkgs; };

          nvim4vscode-unwrapped = nixvim'.makeNixvimWithModule {
            inherit pkgs;
            module = import ./vscode.nix;
          };
        in
        {
          default = nvim-unwrapped;
          nvim = nvim-unwrapped;

          nvim4vscode = pkgs.runCommand "nvim4vscode" { } ''
            mkdir -p $out/bin
            ln -s ${nvim4vscode-unwrapped}/bin/nvim $out/bin/nvim4vscode
          '';
        }
      );
    };
}
