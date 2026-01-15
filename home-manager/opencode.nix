{ config, ... }: {
  programs.opencode = {
    enable = true;
    settings = {
      theme = "catppuccin-espresso";
      mcp = {
        context7 = {
          type = "local";
          enabled = true;
          command = [
            "npx"
            "-y"
            "@upstash/context7-mcp"
            "--api-key"
            "{env:CONTEXT7_API_KEY}"
          ];
        };
      };
      agent = {
        plan = {
          mode = "primary";
          model = "openrouter/anthropic/claude-opus-4.5";
          thinking = {
            type = "enabled";
            budgetTokens = 16000;
          };
        };
        build = {
          mode = "primary";
          model = "openrouter/openai/gpt-5.2";
          reasoningEffort = "high";
        };
      };
    };
  };

  home.sessionVariablesExtra = ''
    export OPENROUTER_API_KEY="$(cat ${config.sops.secrets.openrouter-api-key.path} 2>/dev/null || true)"
    export CONTEXT7_API_KEY="$(cat ${config.sops.secrets.context7-api-key.path} 2>/dev/null || true)"
  '';
}
