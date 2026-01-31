{
  agents,
  agentsInputs,
  config,
  lib,
  system,
  pkgs,
  ...
}:
let
  bun2nix = agentsInputs.bun2nix.packages.${system}.default;

  opencodeAssets = agents + "/opencode";

  localOpencodeAgent = name: {
    inherit name;
    src = "${opencodeAssets}/agents/${name}.md";
  };

  opencodeAgents = [
    (localOpencodeAgent "scout")
    (localOpencodeAgent "docs-digger")
    (localOpencodeAgent "runner")
  ];

  copyOpencodeAgent =
    { name, src }:
    ''
      cp -f "${src}" "${opencodeAgentsDir}/${name}.md"
      chmod +w "${opencodeAgentsDir}/${name}.md"
    '';

  opencodeAgentsDir = "${config.home.homeDirectory}/.config/opencode/agents";

  opencodeCursorAuth = pkgs.callPackage (opencodeAssets + "/pkgs/opencode-cursor-auth/default.nix") {
    inherit bun2nix;
    opencode-cursor-auth-src = agentsInputs."opencode-cursor-auth";
  };
in
{
  home.activation.copyOpencodeTools = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${config.home.homeDirectory}/.config/opencode"
    cp -rf "${opencodeAssets}/tools" "${config.home.homeDirectory}/.config/opencode"
    chmod -R +w "${config.home.homeDirectory}/.config/opencode"
  '';

  # Avoid symlink discovery edge-cases: install agents as real files.
  home.activation.copyOpencodeAgents = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${opencodeAgentsDir}"

    ${lib.concatStringsSep "\n" (map copyOpencodeAgent opencodeAgents)}
  '';

  home.file = {
    ".config/opencode/commands/rmslop.md".source = "${agents}/commands/rmslop.md";
    ".config/opencode/commands/spellcheck.md".source = "${agents}/commands/spellcheck.md";

    ".config/opencode/skills/vcs-detect".source = "${agents}/skills/vcs-detect";
    ".config/opencode/skills/jujutsu".source = "${agents}/skills/jujutsu";
    ".config/opencode/skills/add-nixvim-plugin".source = "${agents}/skills/add-nixvim-plugin";
    ".config/opencode/skills/ast-grep".source =
      "${agentsInputs.astGrepClaudeSkill}/ast-grep/skills/ast-grep";
    ".config/opencode/skills/skill-creator".source =
      "${agentsInputs.anthropicSkills}/skills/skill-creator";

    ".config/opencode/plugins/cursor-auth.ts".text = ''
      export { CursorOAuthPlugin } from "${opencodeCursorAuth}/dist/plugin/index.js";
    '';

    ".config/opencode/AGENTS.md".source = "${opencodeAssets}/_AGENTS.md";
  };

  programs.opencode = {
    enable = true;

    package = agentsInputs.opencode.packages.${system}.default;

    settings = {
      autoupdate = false;

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
            "${pkgs.nodejs}/bin/npx"
            "-y"
            "@upstash/context7-mcp"
            "--api-key"
            "{file:${config.sops.secrets.context7-api-key.path}}"
          ];
        };

        web_search = {
          type = "local";
          enabled = true;
          command = [
            "${pkgs.nodejs}/bin/npx"
            "-y"
            "exa-mcp-server"
          ];
          environment = {
            EXA_API_KEY = "{file:${config.sops.secrets.exa-api-key.path}}";
          };
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

        general.disable = true;
        explore.disable = true;
      };

      plugin = [
        "opencode-pty@0.1.4"
        "@mohak34/opencode-notifier@0.1.15"
        "opencode-websearch-cited@1.2.0"
        "cc-safety-net@0.7.1"
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
            apiKey = "{file:${config.sops.secrets.openrouter-api-key.path}}";
            websearch_cited.model = "x-ai/grok-4.1-fast";
          };
        };

        opencode.options.apiKey = "{file:${config.sops.secrets.opencode-api-key.path}}";

        cursor.name = "Cursor";
      };

      lsp = {
        haskell.disabled = true;
      };

      keybinds = {
        app_exit = "ctrl+d,ctrl+в,<leader>q";
        session_interrupt = "ctrl+c,ctrl+с";
        session_child_cycle = "ctrl+],ctrl+ъ";
        session_child_cycle_reverse = "ctrl+[,ctrl+х";
        input_delete_word_backward = "ctrl+w,ctrl+ц,ctrl+backspace,alt+backspace";
        session_parent = "<leader>o";
      };
    };
  };
}
