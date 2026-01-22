{
  description = "My macos system Nix flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    # zjstatus.url = "github:dj95/zjstatus";
    karabinix.url = "github:pepegar/karabinix";
    jj-starship.url = "github:dmmulroy/jj-starship";

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

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvim = {
      url = "path:./nvim";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixvim.inputs.nixpkgs.follows = "nixpkgs";
    };

    opencode = {
      url = "path:./opencode";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    openspec = {
      url = "github:Fission-AI/OpenSpec";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

      perSystem =
        {
          inputs',
          pkgs,
          system,
          ...
        }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              (final: prev: {
                zjstatus = inputs.zjstatus.packages.${prev.stdenv.hostPlatform.system}.default;
                openspec = inputs.openspec.packages.${prev.stdenv.hostPlatform.system}.default;
                nvim4vscode = inputs.nvim.packages.${prev.stdenv.hostPlatform.system}.nvim4vscode;
                jj-starship = inputs.jj-starship.packages.${prev.stdenv.hostPlatform.system}.default;
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
              pkgs.nixfmt
              pkgs.statix
              pkgs.shellcheck
              pkgs.stylua
            ];
          };

          legacyPackages.homeConfigurations."kremovtort" = inputs.home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              inputs.nvim.homeModules.default
              inputs.opencode.homeModules.default
              ./home-manager/home.nix
            ];
            extraSpecialArgs = {
              inherit system inputs self;
              isLima = false;
            };
          };

          legacyPackages.homeConfigurations."kremovtort@lima-default" =
            inputs.home-manager.lib.homeManagerConfiguration
              {
                inherit pkgs;
                modules = [
                  # inputs.nvim.homeModules.default
                  inputs.opencode.homeModules.default
                  ./home-manager/home.nix
                ];
                extraSpecialArgs = {
                  inherit system inputs self;
                  isLima = true;
                };
              };

          legacyPackages.darwinConfigurations."kremovtort-OSX" = inputs.nix-darwin.lib.darwinSystem {
            modules = [ ./darwin/configuration.nix ];
          };
        };
    };
}
