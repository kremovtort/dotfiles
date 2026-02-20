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
  opencodeAssets = agents + "/opencode";

  localOpencodeAgent = name: {
    inherit name;
    src = "${opencodeAssets}/agents/${name}.md";
  };

  opencodeAgents = [
    (localOpencodeAgent "scout")
    (localOpencodeAgent "docs-digger")
    (localOpencodeAgent "runner")
    (localOpencodeAgent "codemodder")
    (localOpencodeAgent "pair-programming")
  ];

  copyOpencodeAgent =
    { name, src }:
    ''
      cp -f "${src}" "${opencodeAgentsDir}/${name}.md"
      chmod +w "${opencodeAgentsDir}/${name}.md"
    '';

  opencodeAgentsDir = "${config.home.homeDirectory}/.config/opencode/agents";
in
{
  imports = [
    # ./opencode/dcp.nix
  ];

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

    ".config/opencode/instructions/subagent-json-format.md".source =
      "${opencodeAssets}/instructions/subagent-json-format.md";

    ".config/opencode/skills/vcs-detect".source = "${agents}/skills/vcs-detect";
    ".config/opencode/skills/jujutsu".source = "${agents}/skills/jujutsu";
    ".config/opencode/skills/add-nixvim-plugin".source = "${agents}/skills/add-nixvim-plugin";
    ".config/opencode/skills/ast-grep".source =
      "${agentsInputs.astGrepClaudeSkill}/ast-grep/skills/ast-grep";
    ".config/opencode/skills/skill-creator".source =
      "${agentsInputs.anthropicSkills}/skills/skill-creator";

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

      instructions = [
        "${config.home.homeDirectory}/.config/opencode/instructions/subagent-json-format.md"
      ];

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

        MiniMax = {
          type = "local";
          command = [
            "uvx"
            "minimax-coding-plan-mcp"
            "-y"
          ];
          environment = {
            "MINIMAX_API_KEY" = "{file:${config.sops.secrets.minimax-coding-plan-key.path}}";
            "MINIMAX_API_HOST" = "https://api.minimax.io";
          };
          enabled = false;
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

        web_fetch_md = {
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
          model = "openai/gpt-5.3-codex";
        };

        build = {
          mode = "primary";
          model = "openai/gpt-5.3-codex";
        };

        ask = {
          mode = "primary";
          model = "openai/gpt-5.3-codex";
          reasoningEffort = "high";
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
        "cc-safety-net@0.7.1"
        "@vertis/opencode-eliza-auth-plugin@0.3.2"
      ];

      provider = {
        openai = {
          models = {
            "gpt-5.1-codex-mini".options = {
              reasoningEffort = "high";
            };
          };
        };

        minimax.options.apiKey = "{file:${config.sops.secrets.minimax-coding-plan-key.path}}";

        opencode.options.apiKey = "{file:${config.sops.secrets.opencode-api-key.path}}";

        cursor.name = "Cursor";
      };

      lsp = {
        haskell.disabled = true;
      };

      keybinds = {
        leader = "ctrl+x,ctrl+ч";
        app_exit = "ctrl+d,ctrl+в,<leader>q,<leader>й";
        editor_open = "<leader>e,<leader>у";
        theme_list = "<leader>t,<leader>е";
        sidebar_toggle = "<leader>b,<leader>и";
        status_view = "<leader>s,<leader>ы";
        session_export = "<leader>x,<leader>ч";
        session_new = "<leader>n,<leader>т";
        session_list = "<leader>l,<leader>д";
        session_timeline = "<leader>g,<leader>п";
        session_rename = "ctrl+r,ctrl+к";
        session_delete = "ctrl+d,ctrl+в";
        stash_delete = "ctrl+d,ctrl+в";
        model_provider_list = "ctrl+a,ctrl+ф";
        model_favorite_toggle = "ctrl+f,ctrl+а";
        session_interrupt = "ctrl+c,ctrl+с";
        session_compact = "<leader>c,<leader>с";
        messages_page_up = "pageup,ctrl+alt+b,ctrl+alt+и";
        messages_page_down = "pagedown,ctrl+alt+f,ctrl+alt+а";
        messages_line_up = "ctrl+alt+y,ctrl+alt+н";
        messages_line_down = "ctrl+alt+e,ctrl+alt+у";
        messages_half_page_up = "ctrl+alt+u,ctrl+alt+г";
        messages_half_page_down = "ctrl+alt+d,ctrl+alt+в";
        messages_first = "ctrl+g,ctrl+п,home";
        messages_last = "ctrl+alt+g,ctrl+alt+п,end";
        messages_copy = "<leader>y,<leader>н";
        messages_undo = "<leader>u,<leader>г";
        messages_redo = "<leader>r,<leader>к";
        messages_toggle_conceal = "<leader>h,<leader>р";
        model_list = "<leader>m,<leader>ь";
        command_list = "ctrl+p,ctrl+з";
        agent_list = "<leader>a,<leader>ф";
        variant_cycle = "ctrl+t,ctrl+е";
        input_clear = "ctrl+c,ctrl+с";
        input_paste = "ctrl+v,ctrl+м";
        input_newline = "shift+return,ctrl+return,alt+return,ctrl+j,ctrl+о";
        input_move_left = "left,ctrl+b,ctrl+и";
        input_move_right = "right,ctrl+f,ctrl+а";
        input_line_home = "ctrl+a,ctrl+ф";
        input_line_end = "ctrl+e,ctrl+у";
        input_select_line_home = "ctrl+shift+a,ctrl+shift+ф";
        input_select_line_end = "ctrl+shift+e,ctrl+shift+у";
        input_visual_line_home = "alt+a,alt+ф";
        input_visual_line_end = "alt+e,alt+у";
        input_select_visual_line_home = "alt+shift+a,alt+shift+ф";
        input_select_visual_line_end = "alt+shift+e,alt+shift+у";
        input_delete_line = "ctrl+shift+d,ctrl+shift+в";
        input_delete_to_line_end = "ctrl+k,ctrl+л";
        input_delete_to_line_start = "ctrl+u,ctrl+г";
        input_delete = "ctrl+d,ctrl+в,delete,shift+delete";
        input_undo = "ctrl+-,super+z,super+я";
        input_redo = "ctrl+.,ctrl+ю,super+shift+z,super+shift+я";
        input_word_forward = "alt+f,alt+а,alt+right,ctrl+right";
        input_word_backward = "alt+b,alt+и,alt+left,ctrl+left";
        input_select_word_forward = "alt+shift+f,alt+shift+а,alt+shift+right";
        input_select_word_backward = "alt+shift+b,alt+shift+и,alt+shift+left";
        input_delete_word_forward = "alt+d,alt+в,alt+delete,ctrl+delete";
        session_child_cycle = "ctrl+],ctrl+ъ";
        session_child_cycle_reverse = "ctrl+[,ctrl+х";
        input_delete_word_backward = "ctrl+w,ctrl+ц,ctrl+backspace,alt+backspace";
        session_parent = "<leader>o,<leader>щ";
        terminal_suspend = "ctrl+z,ctrl+я";
        tips_toggle = "<leader>h,<leader>р";
      };
    };
  };
}
