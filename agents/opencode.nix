{
  agents,
  agentsInputs,
  config,
  system,
  pkgs,
  ...
}:
let
  bun2nix = agentsInputs.bun2nix.packages.${system}.default;

  opencodeCursorAuth = pkgs.callPackage (agents + "/pkgs/opencode-cursor-auth/default.nix") {
    inherit bun2nix;
    opencode-cursor-auth-src = agentsInputs."opencode-cursor-auth";
  };
in
{
  home.activation.copyOpencodeTools = ''
    cp -rf ${agents}/tools ${config.home.homeDirectory}/.config/opencode
  '';

  home.file = {
    ".config/opencode/commands/rmslop.md".source = "${agents}/commands/rmslop.md";
    ".config/opencode/commands/spellcheck.md".source = "${agents}/commands/spellcheck.md";

    ".config/opencode/skills/vcs-detect".source = "${agents}/skills/vcs-detect";
    ".config/opencode/skills/jujutsu".source = "${agents}/skills/jujutsu";
    ".config/opencode/skills/ast-grep".source =
      "${agentsInputs.astGrepClaudeSkill}/ast-grep/skills/ast-grep";
    ".config/opencode/skills/skill-creator".source =
      "${agentsInputs.anthropicSkills}/skills/skill-creator";

    ".config/opencode/plugins/cursor-auth.ts".text = ''
      export { CursorOAuthPlugin } from "${opencodeCursorAuth}/dist/plugin/index.js";
    '';

    ".config/opencode/AGENTS.md".source = "${agents}/_AGENTS.md";
  };

  programs.opencode = {
    enable = true;

    package = agentsInputs.opencode.packages.${system}.default;

    settings = {
      theme = "catppuccin-espresso";

      compaction = {
        prune = false;
        auto = false;
      };

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

        ask = {
          mode = "primary";
          model = "openai/gpt-5.2";
          reasoningEffort = "low";
          description = "Answer questions and analyze without editing code";
          permission = {
            edit = "deny";
            bash = "allow";
          };
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

        cursor.name = "Cursor";
      };

      lsp = {
        haskell.disabled = true;
      };
    };
  };
}
