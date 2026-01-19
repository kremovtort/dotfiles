{
  config,
  pkgs,
  inputs,
  ...
}:
{
  programs.agent-skills = {
    enable = true;

    targets = {
      opencode = {
        dest = "\${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills";
        structure = "symlink-tree";
      };
    };

    sources = {
      anthropic = {
        path = inputs.anthropicSkills;
        subdir = "skills";
      };

      ast-grep = {
        path = inputs.astGrepClaudeSkill;
        # Repo structure: ast-grep/skills/<skill>/SKILL.md
        subdir = "ast-grep/skills";
      };
    };

    skills.enable = [
      "skill-creator"
      "ast-grep"
    ];
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
        read-website-fast = {
          type = "local";
          enabled = true;
          command = [
            "npx"
            "-y"
            "@just-every/mcp-read-website-fast"
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
        explore = {
          mode = "subagent";
          model = "openai/gpt-5.1-codex-mini";
        };
      };
      plugin = [
        "opencode-pty"
        "@mohak34/opencode-notifier@latest"
        "opencode-websearch-cited@1.2.0"
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
