{
  description = "My macos system Nix flake";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin-ghostty = {
      url = "github:catppuccin/ghostty";
      flake = false;
    };
  };

  outputs = inputs @ { flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "aarch64-darwin" "aarch64-linux" "x86_64-linux" ];

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.just
            pkgs.lua-language-server
            inputs'.home-manager.packages.home-manager
          ] ++ (if system == "aarch64-darwin" then [inputs'.nix-darwin.packages.darwin-rebuild] else []);
        };
        
        homeConfigurations."kremovtort" = inputs'.home-manager.lib.homeManagerConfiguration {
          pkgs = pkgs;
          modules = [ ./home-manager/home.nix ];
          extraSpecialArgs = {
            system = system;
            inputs = inputs';
            flake-self = self';
            catppuccin-ghostty = inputs.catppuccin-ghostty;
          };
        };
      };

      flake = { self, ... }: {
        darwinConfigurations.kremovtort-OSX = inputs.nix-darwin.lib.darwinSystem {
          modules = [
            ./darwin/configuration.nix
          ];
        };
      };
    };
}
