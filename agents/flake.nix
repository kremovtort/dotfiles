{
  description = "OpenCode configuration flake (home-manager module + assets)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    llm-agents.url = "github:numtide/llm-agents.nix";

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
    let
      mkHomeModule = system: {
        _module.args.agentsInputs = inputs;
        _module.args.agents = self;
        _module.args.system = system;

        imports = [
          ./opencode.nix
          ./pi.nix
        ];

        home.packages = [
          inputs.llm-agents.packages.${system}.openspec
        ];
      };
    in
    {
      homeModules = builtins.mapAttrs (system: _: {
        default = mkHomeModule system;
      }) inputs.llm-agents.packages;
    };
}
