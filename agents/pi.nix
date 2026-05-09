{
  agentsInputs,
  config,
  system,
  ...
}:
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

    ".pi/agent/AGENTS.md".text = builtins.concatStringsSep "\n\n" [
      (builtins.readFile ./opencode/instructions/base.md)
      (builtins.readFile ./opencode/instructions/subagent-json-format.md)
    ];

    ".pi/agent/skills".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/agents/skills";

    ".pi/agent/magic-context.jsonc".text = builtins.toJSON {
      "$schema" =
        "https://raw.githubusercontent.com/cortexkit/opencode-magic-context/master/assets/magic-context.schema.json";
      enabled = true;

      cache_ttl = {
        default = "5m";
        "openai-codex/gpt-5.5" = "30m";
      };

      protected_tags = 30;

      historian = {
        model = "openai-codex/gpt-5.5";
        fallback_models = [ "opencode-go/glm-5.1" ];
      };

      nudge_interval_tokens = 25000;

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
  };

}
