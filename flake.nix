{
  description = "My macos system Nix flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { nixpkgs, nix-darwin, home-manager, ... }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      darwinConfigurations.kremovtort-OSX = nix-darwin.lib.darwinSystem {
        modules = [ ./darwin/configuration.nix ];
      };

      homeConfigurations = {
        "kremovtort" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home-manager/home.nix ];
        };
      };

      devShells.aarch64-darwin.default = pkgs.mkShell {
        packages = [
          pkgs.just
          nix-darwin.packages.${system}.darwin-rebuild
          home-manager.packages.${system}.home-manager
        ];
      };
    };
}