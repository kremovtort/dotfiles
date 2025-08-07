{
  description = "My macos system Nix flake";

  inputs = {
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
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ { flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "aarch64-darwin" "aarch64-linux" "x86_64-linux" ];

      perSystem = { config, self', inputs', pkgs, system, lib, ... }: {
        packages.just = inputs'.nixpkgs.legacyPackages.just;
        packages.home-manager = inputs'.home-manager.packages.home-manager;
        packages.darwin-rebuild = inputs'.nix-darwin.packages.darwin-rebuild;

        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.bash-language-server
            pkgs.just
            pkgs.lua-language-server
            pkgs.nil
            pkgs.shellcheck
          ];
        };
        
        legacyPackages.homeConfigurations."kremovtort" = inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home-manager/home.nix ];
          extraSpecialArgs = {
            inherit system;
            flake-self = self;
            catppuccin-ghostty = inputs.catppuccin-ghostty;
          };
        };
        
        legacyPackages.darwinConfigurations.kremovtort-OSX = inputs.nix-darwin.lib.darwinSystem {
          modules = [
            ./darwin/configuration.nix
          ];
        };
      };
    };
}
