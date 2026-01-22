{
  description = "OpenCode configuration flake (home-manager module + assets)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

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
      homeModules.default = import ./home-manager/module.nix { inherit inputs self; };
    };
}
