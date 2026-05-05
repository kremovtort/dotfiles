{
  agents,
  agentsInputs,
  config,
  pkgs,
  system,
  ...
}:
let
  configDir = ".config/opencode";
  magicContextVersion = "0.16.3";
in
{
  home.sessionVariables = {
    MORPH_API_KEY = "\$(cat ${config.sops.secrets.morphllm-key.path} 2> /dev/null || true)";
    OPENCODE_ENABLE_EXA = 1;
  };

  home.file."${configDir}/magic-context.jsonc".text = builtins.toJSON {
    "$schema" =
      "https://raw.githubusercontent.com/cortexkit/opencode-magic-context/master/assets/magic-context.schema.json";
    enabled = true;

    cache_ttl = {
      default = "5m";
      "openai/gpt-5.5" = "30m";
    };

    protected_tags = 30;

    historian.model = "openai/gpt-5.5";

    nudge_interval_tokens = 25000;

    dreamer = {
      enabled = true;
      model = "openai/gpt-5.5";
    };

    sidekick = {
      enabled = true;
      model = "opencode-go/minimax-m2.7";
    };
  };

  home.file."${configDir}/instructions/base.md".source = ./opencode/instructions/base.md;
  home.file."${configDir}/instructions/subagent-json-format.md".source =
    ./opencode/instructions/subagent-json-format.md;

  programs.bun.enable = true; # need for plannotator

  programs.opencode = {
    enable = true;
    package = agentsInputs.llm-agents.packages.${system}.opencode;
    agents = ./opencode/agents;
    commands = ./commands;
    skills = {
      vcs-detect = agents + "/skills/vcs-detect";
      jujutsu = agents + "/skills/jujutsu";
      add-nixvim-plugin = agents + "/skills/add-nixvim-plugin";
      openspec-review = agents + "/skills/openspec-review";
      openspec-review-plan = agents + "/skills/openspec-review-plan";
      openspec-review-apply-fixes = agents + "/skills/openspec-review-apply-fixes";
      openspec-reviewer = agents + "/skills/openspec-reviewer";
      ast-grep = agentsInputs.astGrepClaudeSkill + "/ast-grep/skills/ast-grep";
      skill-creator = agentsInputs.anthropicSkills + "/skills/skill-creator";
    };

    settings = {
      "$schema" = "https://opencode.ai/config.json";

      autoupdate = false;

      plugin = [
        "@mohak34/opencode-notifier@0.2.4"
        "cc-safety-net@0.8.2"
        "opencode-direnv@1.1.1"
        "@plannotator/opencode@0.19.8"
        "@cortexkit/opencode-magic-context@${magicContextVersion}"
        "opencode-morph-fast-apply@github:JRedeker/opencode-morph-fast-apply"
      ];

      instructions = [
        "~/.config/opencode/instructions/*"
        "~/.cache/opencode/packages/opencode-morph-fast-apply@github:JRedeker/opencode-morph-fast-apply/node_modules/opencode-morph-fast-apply/instructions/morph-tools.md"
      ];

      compaction = {
        prune = false;
        auto = false;
      };

      permission.websearch = "allow";

      mcp = {
        context7 = {
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
          model = "openai/gpt-5.5";
          reasoningEffort = "high";
        };

        build = {
          mode = "primary";
          model = "openai/gpt-5.5";
          reasoningEffort = "high";
          tools.morph_edit = true;
        };

        ask = {
          mode = "primary";
          model = "openai/gpt-5.5";
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

      provider = {
        minimax.options.apiKey = "{file:${config.sops.secrets.minimax-coding-plan-key.path}}";

        opencode.options.apiKey = "{file:${config.sops.secrets.opencode-api-key.path}}";

        opencode-go.options.apiKey = "{file:${config.sops.secrets.opencode-api-key.path}}";
      };

      lsp = {
        haskell.disabled = true;
      };
    };

    tui = {
      plugin = [
        "@cortexkit/opencode-magic-context@${magicContextVersion}"
      ];

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
        session_child_first = "ctrl+i,ctrl+ш";
        session_child_cycle = "ctrl+],ctrl+ъ";
        session_child_cycle_reverse = "ctrl+[,ctrl+х";
        input_delete_word_backward = "ctrl+w,ctrl+ц,ctrl+backspace,alt+backspace";
        session_parent = "ctrl+o,ctrl+щ";
        terminal_suspend = "ctrl+z,ctrl+я";
        tips_toggle = "<leader>h,<leader>р";
      };

      theme = "catppuccin-espresso";
    };
  };
}
