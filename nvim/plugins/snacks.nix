{ ... }:
{
  plugins.snacks = {
    enable = true;
    settings = {
      bigfile.enabled = true;
      dashboard = {
        enabled = true;

        # Dashboard-local keybindings (no <leader>)
        preset.keys = [
          {
            icon = " ";
            key = "n";
            desc = "New File";
            action = ":ene | startinsert";
          }
          {
            icon = " ";
            key = "p";
            desc = "Projects";
            action = ":lua Snacks.picker.projects()";
          }
          {
            icon = " ";
            key = "r";
            desc = "Recent Files";
            action = ":lua Snacks.dashboard.pick('oldfiles')";
          }
          {
            icon = " ";
            key = "s";
            desc = "Restore Session";
            action = ":AutoSession restore";
          }
          {
            icon = " ";
            key = "q";
            desc = "Quit";
            action = ":qa";
          }
        ];

        sections = [
          { section = "header"; }
          {
            section = "keys";
            gap = 1;
            padding = 1;
          }
          {
            icon = " ";
            title = "Recent Files";
            section = "recent_files";
            indent = 2;
            padding = 1;
          }
          {
            icon = " ";
            title = "Projects";
            section = "projects";
            indent = 2;
            padding = 1;
          }
        ];
      };
      indent.enabled = true;
      input.enabled = true;
      notifier.enabled = true;
      quickfile.enabled = true;
      picker = {
        enabled = true;
        matcher.cwd_bonus = true;
        matcher.frecency = true;
        win.input.keys = {
          "<a-c>" = {
            __unkeyed-1 = "toggle_cwd";
            mode = [
              "n"
              "i"
            ];
          };
        };
        actions.toggle_cwd.__raw = ''
          function(p)
            local root = vim.fs.root(p.input.filter.current_buf, { ".git", ".jj" })
              or vim.fs.normalize((vim.uv or vim.loop).cwd() or ".")
            local cwd = vim.fs.normalize((vim.uv or vim.loop).cwd() or ".")
            local current = p:cwd()
            p:set_cwd(current == root and cwd or root)
            p:find()
          end
        '';
      };
      scope.enabled = true;
      scroll.enabled = false;
      statuscolumn.enabled = false;
      words.enabled = true;
      terminal.win.keys = { };
    };
  };

  keymaps = [
    {
      mode = "n";
      key = "<leader>e";
      action.__raw = ''
        function()
          require("snacks").picker.pick({
            source = "explorer",
            jump = {close = true},
            auto_close = true,
            layout = {preset = "default", preview = "preview"},
            win = {
              list = {
                keys = {
                  ["<C-c>"] = "close",
                  ["<C-t>"] = "",
                },
              },
            },
          })
        end
      '';
    }
    {
      mode = "n";
      key = "<leader>n";
      action.__raw = "function() require('snacks').picker.notifications() end";
      options.desc = "Notification History";
    }
    {
      mode = "n";
      key = "<leader>un";
      action.__raw = "function() require('snacks').notifier.hide() end";
      options.desc = "Dismiss All Notifications";
    }
    {
      mode = "n";
      key = "<leader>.";
      action.__raw = "function() require('snacks').scratch() end";
      options.desc = "Toggle Scratch Buffer";
    }
    {
      mode = "n";
      key = "<leader>S";
      action.__raw = "function() require('snacks').scratch.select() end";
      options.desc = "Select Scratch Buffer";
    }
    {
      mode = "n";
      key = "<leader>dps";
      action.__raw = "function() require('snacks').profiler.scratch() end";
      options.desc = "Profiler Scratch Buffer";
    }
    {
      mode = "n";
      key = "<leader>,";
      action.__raw = "function() require('snacks').picker.buffers() end";
      options.desc = "Buffers";
    }
    {
      mode = "n";
      key = "<leader>/";
      action.__raw = ''
        function()
          local root = vim.fs.root(0, { ".git", ".jj" }) or vim.fs.normalize((vim.uv or vim.loop).cwd() or ".")
          require("snacks").picker.grep({ cwd = root })
        end
      '';
      options.desc = "Grep (Root Dir)";
    }
    {
      mode = "n";
      key = "<leader>:";
      action.__raw = "function() require('snacks').picker.command_history() end";
      options.desc = "Command History";
    }
    {
      mode = "n";
      key = "<leader><space>";
      action.__raw = ''
        function()
          local root = vim.fs.root(0, { ".git", ".jj" }) or vim.fs.normalize((vim.uv or vim.loop).cwd() or ".")
          require("snacks").picker.files({ cwd = root })
        end
      '';
      options.desc = "Find Files (Root Dir)";
    }
    {
      mode = "n";
      key = "<leader>fb";
      action.__raw = "function() require('snacks').picker.buffers() end";
      options.desc = "Buffers";
    }
    {
      mode = "n";
      key = "<leader>fB";
      action.__raw = "function() require('snacks').picker.buffers({ hidden = true, nofile = true }) end";
      options.desc = "Buffers (all)";
    }
    {
      mode = "n";
      key = "<leader>fc";
      action.__raw = "function() require('snacks').picker.files({ cwd = vim.fn.stdpath('config') }) end";
      options.desc = "Find Config File";
    }
    {
      mode = "n";
      key = "<leader>ff";
      action.__raw = ''
        function()
          local root = vim.fs.root(0, { ".git", ".jj" }) or vim.fs.normalize((vim.uv or vim.loop).cwd() or ".")
          require("snacks").picker.files({ cwd = root })
        end
      '';
      options.desc = "Find Files (Root Dir)";
    }
    {
      mode = "n";
      key = "<leader>fF";
      action.__raw = "function() require('snacks').picker.files({ cwd = (vim.uv or vim.loop).cwd() or '.' }) end";
      options.desc = "Find Files (cwd)";
    }
    {
      mode = "n";
      key = "<leader>fg";
      action.__raw = "function() require('snacks').picker.git_files() end";
      options.desc = "Find Files (git-files)";
    }
    {
      mode = "n";
      key = "<leader>fr";
      action.__raw = "function() require('snacks').picker.recent() end";
      options.desc = "Recent";
    }
    {
      mode = "n";
      key = "<leader>fR";
      action.__raw = "function() require('snacks').picker.recent({ filter = { cwd = true } }) end";
      options.desc = "Recent (cwd)";
    }
    {
      mode = "n";
      key = "<leader>fp";
      action.__raw = "function() require('snacks').picker.projects() end";
      options.desc = "Projects";
    }
    {
      mode = "n";
      key = "<leader>jd";
      action.__raw = "function() require('snacks').picker.git_diff() end";
      options.desc = "Git Diff (hunks)";
    }
    {
      mode = "n";
      key = "<leader>jD";
      action.__raw = "function() require('snacks').picker.git_diff({ base = 'origin', group = true }) end";
      options.desc = "Git Diff (origin)";
    }
    {
      mode = "n";
      key = "<leader>js";
      action.__raw = "function() require('snacks').picker.git_status() end";
      options.desc = "Git Status";
    }
    {
      mode = "n";
      key = "<leader>jS";
      action.__raw = "function() require('snacks').picker.git_stash() end";
      options.desc = "Git Stash";
    }
    {
      mode = "n";
      key = "<leader>sb";
      action.__raw = "function() require('snacks').picker.lines() end";
      options.desc = "Buffer Lines";
    }
    {
      mode = "n";
      key = "<leader>sB";
      action.__raw = "function() require('snacks').picker.grep_buffers() end";
      options.desc = "Grep Open Buffers";
    }
    {
      mode = "n";
      key = "<leader>sg";
      action.__raw = ''
        function()
          local root = vim.fs.root(0, { ".git", ".jj" }) or vim.fs.normalize((vim.uv or vim.loop).cwd() or ".")
          require("snacks").picker.grep({ cwd = root })
        end
      '';
      options.desc = "Grep (Root Dir)";
    }
    {
      mode = "n";
      key = "<leader>sG";
      action.__raw = "function() require('snacks').picker.grep({ cwd = (vim.uv or vim.loop).cwd() or '.' }) end";
      options.desc = "Grep (cwd)";
    }
    {
      mode = "n";
      key = "<leader>sp";
      action.__raw = "function() require('snacks').picker.lazy() end";
      options.desc = "Search for Plugin Spec";
    }
    {
      mode = [
        "n"
        "x"
      ];
      key = "<leader>sw";
      action.__raw = ''
        function()
          local root = vim.fs.root(0, { ".git", ".jj" }) or vim.fs.normalize((vim.uv or vim.loop).cwd() or ".")
          require("snacks").picker.grep_word({ cwd = root })
        end
      '';
      options.desc = "Visual selection or word (Root Dir)";
    }
    {
      mode = [
        "n"
        "x"
      ];
      key = "<leader>sW";
      action.__raw = "function() require('snacks').picker.grep_word({ cwd = (vim.uv or vim.loop).cwd() or '.' }) end";
      options.desc = "Visual selection or word (cwd)";
    }
    {
      mode = "n";
      key = ''<leader>s"'';
      action.__raw = "function() require('snacks').picker.registers() end";
      options.desc = "Registers";
    }
    {
      mode = "n";
      key = "<leader>s/";
      action.__raw = "function() require('snacks').picker.search_history() end";
      options.desc = "Search History";
    }
    {
      mode = "n";
      key = "<leader>sa";
      action.__raw = "function() require('snacks').picker.autocmds() end";
      options.desc = "Autocmds";
    }
    {
      mode = "n";
      key = "<leader>sc";
      action.__raw = "function() require('snacks').picker.command_history() end";
      options.desc = "Command History";
    }
    {
      mode = "n";
      key = "<leader>sC";
      action.__raw = "function() require('snacks').picker.commands() end";
      options.desc = "Commands";
    }
    {
      mode = "n";
      key = "<leader>sd";
      action.__raw = "function() require('snacks').picker.diagnostics() end";
      options.desc = "Diagnostics";
    }
    {
      mode = "n";
      key = "<leader>sD";
      action.__raw = "function() require('snacks').picker.diagnostics_buffer() end";
      options.desc = "Buffer Diagnostics";
    }
    {
      mode = "n";
      key = "<leader>sh";
      action.__raw = "function() require('snacks').picker.help() end";
      options.desc = "Help Pages";
    }
    {
      mode = "n";
      key = "<leader>sH";
      action.__raw = "function() require('snacks').picker.highlights() end";
      options.desc = "Highlights";
    }
    {
      mode = "n";
      key = "<leader>si";
      action.__raw = "function() require('snacks').picker.icons() end";
      options.desc = "Icons";
    }
    {
      mode = "n";
      key = "<leader>sj";
      action.__raw = "function() require('snacks').picker.jumps() end";
      options.desc = "Jumps";
    }
    {
      mode = "n";
      key = "<leader>sk";
      action.__raw = "function() require('snacks').picker.keymaps() end";
      options.desc = "Keymaps";
    }
    {
      mode = "n";
      key = "<leader>sl";
      action.__raw = "function() require('snacks').picker.loclist() end";
      options.desc = "Location List";
    }
    {
      mode = "n";
      key = "<leader>sM";
      action.__raw = "function() require('snacks').picker.man() end";
      options.desc = "Man Pages";
    }
    {
      mode = "n";
      key = "<leader>sm";
      action.__raw = "function() require('snacks').picker.marks() end";
      options.desc = "Marks";
    }
    {
      mode = "n";
      key = "<leader>sR";
      action.__raw = "function() require('snacks').picker.resume() end";
      options.desc = "Resume";
    }
    {
      mode = "n";
      key = "<leader>sq";
      action.__raw = "function() require('snacks').picker.qflist() end";
      options.desc = "Quickfix List";
    }
    {
      mode = "n";
      key = "<leader>su";
      action.__raw = "function() require('snacks').picker.undo() end";
      options.desc = "Undotree";
    }
    {
      mode = "n";
      key = "<leader>uC";
      action.__raw = "function() require('snacks').picker.colorschemes() end";
      options.desc = "Colorschemes";
    }
  ];
}
