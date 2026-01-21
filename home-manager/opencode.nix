{
  config,
  pkgs,
  inputs,
  flake-self,
  ...
}:
{
  home.file = {
    ".config/opencode/oh-my-opencode-slim.json".source = "${flake-self}/opencode/oh-my-opencode-slim.json";
    ".config/opencode/commands/rmslop.md".source = "${flake-self}/opencode/commands/rmslop.md";
    ".config/opencode/commands/spellcheck.md".source = "${flake-self}/opencode/commands/spellcheck.md";
    ".config/opencode/skills/vsc-detect".source = "${flake-self}/opencode/skills/vsc-detect/";
    ".config/opencode/skills/ast-grep".source = "${inputs.astGrepClaudeSkill}/ast-grep/skills/ast-grep";
    ".config/opencode/skills/skill-creator".source = "${inputs.anthropicSkills}/skills/skill-creator";
  };

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
            "{file:${config.sops.secrets.context7-api-key.path}}"
          ];
        };
      };
      agent = {
        plan = {
          mode = "primary";
          model = "openai/gpt-5.2";
        };
        build = {
          mode = "primary";
          model = "openai/gpt-5.2";
        };
        general = {
          mode = "subagent";
          model = "openai/gpt-5.1-codex-mini";
        };
      };
      plugin = [
        "opencode-pty"
        "@mohak34/opencode-notifier@latest"
        "opencode-websearch-cited@1.2.0"
        "cc-safety-net"
        "oh-my-opencode-slim"
      ];
      provider = {
        openai = {
          models = {
            "gpt-5.1-codex-mini".options = {
              reasoningEffort = "high";
            };
          };
        };
        openrouter = {
          options = {
            websearch_cited.model = "x-ai/grok-4.1-fast";
          };
        };
      };
      lsp = {
        haskell.disabled = true;
      };
    };
  };
}
