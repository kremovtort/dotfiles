{
  description = "OpenCode configuration flake (home-manager module + assets)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    openspec = {
      url = "github:Fission-AI/OpenSpec";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    opencode = {
      url = "github:anomalyco/opencode";
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
        {
          _module.args.agentsInputs = inputs;
          _module.args.agents = self;

          imports = [
            ./opencode.nix
          ];

          home.packages = [ inputs.openspec.packages.${system}.default ];
        };
    };
}
