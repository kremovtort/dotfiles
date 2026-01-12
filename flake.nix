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
    paneru = {
      url = "github:karinushka/paneru";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    zjstatus.url = "github:dj95/zjstatus";
    karabinix.url = "github:pepegar/karabinix";
    openspec-flake.url = "github:kremovtort/openspec-flake";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "aarch64-darwin" "aarch64-linux" "x86_64-linux" ];

      perSystem = { inputs', pkgs, system, ... }: {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            (final: prev: {
              zjstatus = inputs.zjstatus.packages.${prev.stdenv.hostPlatform.system}.default;
            })
          ];
          config = { };
        };
        packages.just = inputs'.nixpkgs.legacyPackages.just;
        packages.home-manager = inputs'.home-manager.packages.home-manager;
        packages.darwin-rebuild = inputs'.nix-darwin.packages.darwin-rebuild;

        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.bash-language-server
            pkgs.just
            pkgs.lua-language-server
            pkgs.nixd
            pkgs.statix
            pkgs.shellcheck
            pkgs.stylua
          ];
        };
        
        legacyPackages.homeConfigurations."kremovtort" = inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            inputs.karabinix.homeManagerModules.karabinix
            inputs.paneru.homeModules.paneru
            inputs.sops-nix.homeManagerModules.sops
            ./home-manager/home.nix
          ];
          extraSpecialArgs = {
            inherit system inputs;
            flake-self = self;
          };
        };
        
        legacyPackages.darwinConfigurations."kremovtort-OSX" = inputs.nix-darwin.lib.darwinSystem {
          modules = [ ./darwin/configuration.nix ];
        };
      };
    };
}
