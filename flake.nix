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
    make-shell.url = "github:nicknovitski/make-shell";
  };

  outputs = inputs @ { flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "aarch64-darwin" "aarch64-linux" "x86_64-linux" ];
      
      imports = [
        inputs.make-shell.flakeModules.default
      ];

      perSystem = { config, self', inputs', pkgs, system, lib, ... }: {
        make-shells.default = {
          packages = [
            pkgs.just
            pkgs.lua-language-server
            inputs'.home-manager.packages.home-manager
          ] ++ (if system == "aarch64-darwin" then [inputs'.nix-darwin.packages.darwin-rebuild] else []);
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
