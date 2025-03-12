{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system} // {
      config.allowUnfree = true;
    };
  in{
    homeConfigurations."kremovtort" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [ ./home-manager/home.nix ];
    };
    devShell.${system} = pkgs.mkShell {
      buildInputs = [ pkgs.just ];
    };
  };
}