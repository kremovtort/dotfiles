{
  description = "My macos system Nix flake";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nix-rosetta-builder = {
    #   url = "github:cpick/nix-rosetta-builder";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    catppuccin-ghostty = {
      url = "github:catppuccin/ghostty";
      flake = false;
    };
  };

  outputs = { nixpkgs, nix-darwin, home-manager, flake-utils, catppuccin-ghostty, ... }:
    flake-utils.lib.eachSystem [ "aarch64-darwin" "x86_64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        isDarwin = system == "aarch64-darwin";
      in {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.just
            pkgs.lua-language-server
            home-manager.packages.${system}.home-manager
          ] ++ (if isDarwin then [nix-darwin.packages.${system}.darwin-rebuild] else []);
        };
      }
    ) // {
      homeConfigurations."kremovtort@kremovtort-OSX" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        modules = [ ./home-manager/home.nix ];
        extraSpecialArgs = {
          system = "aarch64-darwin";
          inherit catppuccin-ghostty;
        };
      };
      
      homeConfigurations.kremovtort = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [ ./home-manager/home.nix ];
        extraSpecialArgs = {
          system = "x86_64-linux";
          inherit catppuccin-ghostty;
        };
      };

      darwinConfigurations.kremovtort-OSX = nix-darwin.lib.darwinSystem {
        modules = [
          # nix-rosetta-builder.darwinModules.default
          ./darwin/configuration.nix
        ];
      };
    };
}
