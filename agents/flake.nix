{
  description = "OpenCode configuration flake (home-manager module + assets)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgsNode20.url = "github:NixOS/nixpkgs/400de68cd101e8cfebffea121397683caf7f5a34";

    openspec = {
      url = "github:Fission-AI/OpenSpec";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    anthropicSkills = {
      url = "github:anthropics/skills";
      flake = false;
    };

    astGrepClaudeSkill = {
      url = "github:ast-grep/claude-skill";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      ...
    }:
    {
      homeModules.default =
        { system, ... }:
        let
          openspecPackage =
            if system == "aarch64-darwin" then
              let
                pinnedPkgs = import inputs.nixpkgsNode20 {
                  inherit system;
                };
              in
              inputs.openspec.packages.${system}.default.overrideAttrs (old: {
                nativeBuildInputs = map (
                  pkg: if (pkg.pname or "") == "nodejs" then pinnedPkgs.nodejs_20 else pkg
                ) old.nativeBuildInputs;
              })
            else
              inputs.openspec.packages.${system}.default;
        in
        {
          _module.args.agentsInputs = inputs;
          _module.args.agents = self;

          imports = [
            ./opencode.nix
          ];

          home.packages = [ openspecPackage ];
        };
    };
}
