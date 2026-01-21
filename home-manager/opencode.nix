{
  config,
  pkgs,
  inputs,
  flake-self,
  ...
}:
{
  home.file = {
    ".config/opencode/commands/rmslop.md".source = "${flake-self}/opencode/commands/rmslop.md";
    ".config/opencode/commands/spellcheck.md".source = "${flake-self}/opencode/commands/spellcheck.md";
    ".config/opencode/skills/vcs-detect".source = "${flake-self}/opencode/skills/vcs-detect";
    ".config/opencode/skills/ast-grep".source = "${inputs.astGrepClaudeSkill}/ast-grep/skills/ast-grep";
    ".config/opencode/skills/skill-creator".source = "${inputs.anthropicSkills}/skills/skill-creator";
  };

  programs.opencode = {
    enable = true;

    settings = {
      theme = "catppuccin-espresso";
      mcp = {
        docs_search = {
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
        web_search = {
          type = "remote";
          enabled = false;
          url = "https://api.z.ai/api/mcp/web_search_prime/mcp";
          headers.Authorization = "Bearer {file:${config.sops.secrets.zai-api-key.path}}";
        };
        grep_app = {
          type = "remote";
          enabled = true;
          url = "https://mcp.grep.app";
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
        "opencode-websearch-cited@latest"
        "cc-safety-net"
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
