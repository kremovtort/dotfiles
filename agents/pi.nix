{
  agents,
  agentsInputs,
  config,
  lib,
  system,
  ...
}:
let
  localSkillDirs = lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./skills);

  localSkillFiles = lib.mapAttrs' (name: _: {
    name = ".pi/agent/skills/${name}";
    value.source = agents + "/skills/${name}";
  }) localSkillDirs;

  flakeSkillFiles = {
    ".pi/agent/skills/ast-grep".source = agentsInputs.astGrepClaudeSkill + "/ast-grep/skills/ast-grep";
    ".pi/agent/skills/skill-creator".source = agentsInputs.anthropicSkills + "/skills/skill-creator";
  };
in
{
  home.packages = [
    agentsInputs.llm-agents.packages.${system}.pi
  ];

  home.file = {
    ".pi/agent/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/agents/pi/settings.json";

    ".pi/agent/themes/catppuccin-espresso.json".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/catppuccin/pi-theme-catppuccin-espresso.json";

    ".pi/agent/agents".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/agents/pi/agents";

    ".pi/agent/packages/agent-permission-framework".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/agents/pi/packages/agent-permission-framework";

    ".pi/agent/AGENTS.md".text = builtins.concatStringsSep "\n\n" [
      (builtins.readFile ./opencode/instructions/base.md)
      (builtins.readFile ./opencode/instructions/subagent-json-format.md)
    ];

    ".pi/agent/magic-context.jsonc".text = builtins.toJSON {
      "$schema" =
        "https://raw.githubusercontent.com/cortexkit/opencode-magic-context/master/assets/magic-context.schema.json";

      enabled = true;

      cache_ttl = {
        default = "5m";
        "openai-codex/gpt-5.5" = "5m";
      };
      nudge_interval_tokens = 7500;
      iteration_nudge_threshold = 8;
      execute_threshold_percentage = 50;
      auto_drop_tool_age = 60;
      protected_tags = 20;

      historian = {
        model = "openai-codex/gpt-5.5";
        fallback_models = [ "opencode-go/glm-5.1" ];
      };


      dreamer = {
        enabled = true;
        model = "openai-codex/gpt-5.5";
      };

      sidekick = {
        enabled = true;
        model = "opencode-go/minimax-m2.7";
      };

      embedding = {
        provider = "local";
        model = "Xenova/all-MiniLM-L6-v2";
      };
    };
  }
  // flakeSkillFiles
  // localSkillFiles;

}
