{
  description = "OpenCode configuration flake (home-manager module + assets)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    bun2nix = {
      url = "git+https://github.com/nix-community/bun2nix?ref=refs/tags/2.0.6";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    opencode = {
      url = "github:anomalyco/opencode";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    opencode-cursor-auth = {
      url = "github:Yukaii/yet-another-opencode-cursor-auth";
      flake = false;
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
      homeModules.default = {
        _module.args.agentsInputs = inputs;
        _module.args.agents = self;

        imports = [
          ./cursor.nix
          ./opencode.nix
        ];
      };
    };
}
