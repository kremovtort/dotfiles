{
  programs.nixvim.keymaps = [
    # Better up/down for wrapped lines
    {
      mode = [
        "n"
        "x"
      ];
      key = "j";
      action.__raw = "function() return vim.v.count == 0 and 'gj' or 'j' end";
      options = {
        expr = true;
        desc = "Down";
      };
    }
    {
      mode = [
        "n"
        "x"
      ];
      key = "<Down>";
      action.__raw = "function() return vim.v.count == 0 and 'gj' or 'j' end";
      options = {
        expr = true;
        desc = "Down";
      };
    }
    {
      mode = [
        "n"
        "x"
      ];
      key = "k";
      action.__raw = "function() return vim.v.count == 0 and 'gk' or 'k' end";
      options = {
        expr = true;
        desc = "Up";
      };
    }
    {
      mode = [
        "n"
        "x"
      ];
      key = "<Up>";
      action.__raw = "function() return vim.v.count == 0 and 'gk' or 'k' end";
      options = {
        expr = true;
        desc = "Up";
      };
    }

    # Window navigation (disabled in floating windows)
    {
      mode = "n";
      key = "<C-h>";
      action.__raw = ''
        function()
          local cfg = vim.api.nvim_win_get_config(0)
          if cfg.relative ~= "" then return "<Ignore>" end
          return "<C-w>h"
        end
      '';
      options = {
        expr = true;
        desc = "Go to Left Window";
      };
    }
    {
      mode = "n";
      key = "<C-j>";
      action.__raw = ''
        function()
          local cfg = vim.api.nvim_win_get_config(0)
          if cfg.relative ~= "" then return "<Ignore>" end
          return "<C-w>j"
        end
      '';
      options = {
        expr = true;
        desc = "Go to Lower Window";
      };
    }
    {
      mode = "n";
      key = "<C-k>";
      action.__raw = ''
        function()
          local cfg = vim.api.nvim_win_get_config(0)
          if cfg.relative ~= "" then return "<Ignore>" end
          return "<C-w>k"
        end
      '';
      options = {
        expr = true;
        desc = "Go to Upper Window";
      };
    }
    {
      mode = "n";
      key = "<C-l>";
      action.__raw = ''
        function()
          local cfg = vim.api.nvim_win_get_config(0)
          if cfg.relative ~= "" then return "<Ignore>" end
          return "<C-w>l"
        end
      '';
      options = {
        expr = true;
        desc = "Go to Right Window";
      };
    }

    # Resize windows
    {
      mode = "n";
      key = "<C-Up>";
      action = "<cmd>resize +2<cr>";
      options.desc = "Increase Window Height";
    }
    {
      mode = "n";
      key = "<C-Down>";
      action = "<cmd>resize -2<cr>";
      options.desc = "Decrease Window Height";
    }
    {
      mode = "n";
      key = "<C-Left>";
      action = "<cmd>vertical resize -2<cr>";
      options.desc = "Decrease Window Width";
    }
    {
      mode = "n";
      key = "<C-Right>";
      action = "<cmd>vertical resize +2<cr>";
      options.desc = "Increase Window Width";
    }

    # Move lines
    {
      mode = "n";
      key = "<A-j>";
      action = "<cmd>m .+1<cr>==";
      options.desc = "Move Down";
    }
    {
      mode = "n";
      key = "<A-k>";
      action = "<cmd>m .-2<cr>==";
      options.desc = "Move Up";
    }
    {
      mode = "v";
      key = "<A-j>";
      action = ":m '>+1<cr>gv=gv";
      options.desc = "Move Down";
    }
    {
      mode = "v";
      key = "<A-k>";
      action = ":m '<-2<cr>gv=gv";
      options.desc = "Move Up";
    }
    {
      mode = "i";
      key = "<A-j>";
      action = "<esc><cmd>m .+1<cr>==gi";
      options.desc = "Move Down";
    }
    {
      mode = "i";
      key = "<A-k>";
      action = "<esc><cmd>m .-2<cr>==gi";
      options.desc = "Move Up";
    }

    # Buffer navigation
    {
      mode = "n";
      key = "<S-h>";
      action = "<cmd>bprevious<cr>";
      options.desc = "Prev Buffer";
    }
    {
      mode = "n";
      key = "<S-l>";
      action = "<cmd>bnext<cr>";
      options.desc = "Next Buffer";
    }
    {
      mode = "n";
      key = "[b";
      action = "<cmd>bprevious<cr>";
      options.desc = "Prev Buffer";
    }
    {
      mode = "n";
      key = "]b";
      action = "<cmd>bnext<cr>";
      options.desc = "Next Buffer";
    }
    {
      mode = "n";
      key = "<leader>bb";
      action = "<cmd>buffer #<cr>";
      options.desc = "Switch to Other Buffer";
    }
    {
      mode = "n";
      key = "<leader>`";
      action = "<cmd>buffer #<cr>";
      options.desc = "Switch to Other Buffer";
    }

    # Buffer delete
    {
      mode = "n";
      key = "<leader>bd";
      action.__raw = ''
        function()
          local bufnr = 0
          if vim.bo[bufnr].modified then
            local choice = vim.fn.confirm("Buffer modified. Delete anyway?", "&Yes\n&No", 2)
            if choice ~= 1 then return end
          end
          vim.api.nvim_buf_delete(bufnr, { force = true })
        end
      '';
      options.desc = "Delete Buffer";
    }

    # Delete other buffers
    {
      mode = "n";
      key = "<leader>bo";
      action.__raw = ''
        function()
          local current = vim.api.nvim_get_current_buf()
          for _, b in ipairs(vim.api.nvim_list_bufs()) do
            if b ~= current and vim.api.nvim_buf_is_loaded(b) and vim.bo[b].buflisted then
              pcall(vim.api.nvim_buf_delete, b, { force = true })
            end
          end
        end
      '';
      options.desc = "Delete Other Buffers";
    }

    # Neo-tree
    {
      mode = "n";
      key = "<leader>e";
      action = "<cmd>Neotree toggle<cr>";
      options.desc = "Explorer (Neo-tree)";
    }

    # Edgy panel toggles (Cmd+[, Cmd+], Cmd+')
    {
      mode = "n";
      key = "<D-[>";
      action.__raw = "function() require('edgy').toggle('left') end";
      options.desc = "Toggle Left Panel";
    }
    {
      mode = "n";
      key = "<D-]>";
      action.__raw = "function() require('edgy').toggle('right') end";
      options.desc = "Toggle Right Panel";
    }
    {
      mode = "n";
      key = "<D-'>";
      action.__raw = "function() require('edgy').toggle('bottom') end";
      options.desc = "Toggle Bottom Panel";
    }

    # Toggleterm (Ctrl+/)
    {
      mode = [
        "n"
        "t"
      ];
      key = "<C-/>";
      action = "<cmd>ToggleTerm direction=float<cr>";
      options.desc = "Toggle terminal";
    }

    # jjui in floating toggleterm
    {
      mode = [
        "n"
        "t"
      ];
      key = "<D-j>";
      action.__raw = ''
        function()
          local Terminal = require("toggleterm.terminal").Terminal

          if not _G.__jjui_term then
            _G.__jjui_term = Terminal:new({
              cmd = "jjui",
              direction = "float",
              hidden = true,
              close_on_exit = false,
              on_open = function(_)
                vim.cmd("startinsert!")
              end,
              on_exit = function(_, _, exit_code)
                -- If jjui exited successfully, hide the terminal.
                if exit_code == 0 then
                  pcall(vim.cmd, "close")
                end
                -- Always drop the instance so next open is fresh.
                _G.__jjui_term = nil
              end,
              -- Run in current Neovim cwd
              cwd = function()
                return (vim.uv or vim.loop).cwd() or vim.fn.getcwd()
              end,
            })
          end

          _G.__jjui_term:toggle()
        end
      '';
      options.desc = "jjui (float)";
    }

    # Escape and clear search highlight
    {
      mode = [
        "i"
        "n"
        "s"
      ];
      key = "<esc>";
      action.__raw = ''
        function()
          vim.cmd("nohlsearch")
          return "<esc>"
        end
      '';
      options = {
        expr = true;
        desc = "Escape and Clear hlsearch";
      };
    }

    # Redraw / Clear hlsearch / Diff Update
    {
      mode = "n";
      key = "<leader>ur";
      action.__raw = ''
        function()
          vim.cmd("nohlsearch")
          vim.cmd("diffupdate")
          vim.cmd("redraw")
        end
      '';
      options.desc = "Redraw / Clear hlsearch / Diff Update";
    }

    # Better search result navigation
    {
      mode = [
        "n"
        "x"
        "o"
      ];
      key = "n";
      action = "nzzzv";
      options.desc = "Next Search Result";
    }
    {
      mode = [
        "n"
        "x"
        "o"
      ];
      key = "N";
      action = "Nzzzv";
      options.desc = "Prev Search Result";
    }

    # Save file
    {
      mode = [
        "i"
        "x"
        "n"
        "s"
      ];
      key = "<C-s>";
      action = "<cmd>silent! write<cr>";
      options.desc = "Save File";
    }

    # Keywordprg
    {
      mode = "n";
      key = "<leader>K";
      action = "<cmd>normal! K<cr>";
      options.desc = "Keywordprg";
    }

    # New file
    {
      mode = "n";
      key = "<leader>fn";
      action = "<cmd>enew<cr>";
      options.desc = "New File";
    }

    # Quickfix / Location list navigation
    {
      mode = "n";
      key = "[q";
      action = "<cmd>cprevious<cr>";
      options.desc = "Previous Quickfix";
    }
    {
      mode = "n";
      key = "]q";
      action = "<cmd>cnext<cr>";
      options.desc = "Next Quickfix";
    }

    # LSP / diagnostics

    # Toggles
    {
      mode = "n";
      key = "<leader>us";
      action.__raw = "function() vim.o.spell = not vim.o.spell end";
      options.desc = "Toggle Spelling";
    }
    {
      mode = "n";
      key = "<leader>uw";
      action.__raw = "function() vim.o.wrap = not vim.o.wrap end";
      options.desc = "Toggle Wrap";
    }
    {
      mode = "n";
      key = "<leader>uL";
      action.__raw = "function() vim.o.relativenumber = not vim.o.relativenumber end";
      options.desc = "Toggle Relative Number";
    }
    {
      mode = "n";
      key = "<leader>ul";
      action.__raw = "function() vim.o.number = not vim.o.number end";
      options.desc = "Toggle Line Numbers";
    }
    {
      mode = "n";
      key = "<leader>uc";
      action.__raw = "function() vim.o.conceallevel = vim.o.conceallevel == 0 and 2 or 0 end";
      options.desc = "Toggle Conceal Level";
    }
    {
      mode = "n";
      key = "<leader>uA";
      action.__raw = "function() vim.o.showtabline = vim.o.showtabline == 0 and 2 or 0 end";
      options.desc = "Toggle Tabline";
    }
    {
      mode = "n";
      key = "<leader>ub";
      action.__raw = ''function() vim.o.background = vim.o.background == "dark" and "light" or "dark" end'';
      options.desc = "Toggle Dark Background";
    }
    {
      mode = "n";
      key = "<leader>ua";
      action.__raw = "function() vim.g.snacks_animate = not vim.g.snacks_animate end";
      options.desc = "Toggle Animations";
    }
    {
      mode = "n";
      key = "<leader>ud";
      action.__raw = ''
        function()
          local enabled = vim.g._kremovtort_diag_enabled
          if enabled == nil then enabled = true end
          enabled = not enabled
          vim.g._kremovtort_diag_enabled = enabled
          vim.diagnostic.enable(enabled)
        end
      '';
      options.desc = "Toggle Diagnostics";
    }
    {
      mode = "n";
      key = "<leader>uh";
      action.__raw = ''
        function()
          local ok = pcall(function()
            local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
            vim.lsp.inlay_hint.enable(not enabled, { bufnr = 0 })
          end)
          if not ok then
            vim.notify("Inlay hints not supported in this Neovim/LSP setup", vim.log.levels.WARN)
          end
        end
      '';
      options.desc = "Toggle Inlay Hints";
    }

    # Terminal window navigation (pass through in floating windows)
    {
      mode = "t";
      key = "<C-h>";
      action.__raw = ''
        function()
          local cfg = vim.api.nvim_win_get_config(0)
          if cfg.relative ~= "" then
            return vim.api.nvim_replace_termcodes("<C-h>", true, false, true)
          end
          return vim.api.nvim_replace_termcodes("<C-\\><C-n><C-w>h", true, false, true)
        end
      '';
      options = {
        silent = true;
        expr = true;
        desc = "Go to Left Window";
      };
    }
    {
      mode = "t";
      key = "<C-j>";
      action.__raw = ''
        function()
          local cfg = vim.api.nvim_win_get_config(0)
          if cfg.relative ~= "" then
            return vim.api.nvim_replace_termcodes("<C-j>", true, false, true)
          end
          return vim.api.nvim_replace_termcodes("<C-\\><C-n><C-w>j", true, false, true)
        end
      '';
      options = {
        silent = true;
        expr = true;
        desc = "Go to Lower Window";
      };
    }
    {
      mode = "t";
      key = "<C-k>";
      action.__raw = ''
        function()
          local cfg = vim.api.nvim_win_get_config(0)
          if cfg.relative ~= "" then
            return vim.api.nvim_replace_termcodes("<C-k>", true, false, true)
          end
          return vim.api.nvim_replace_termcodes("<C-\\><C-n><C-w>k", true, false, true)
        end
      '';
      options = {
        silent = true;
        expr = true;
        desc = "Go to Upper Window";
      };
    }
    {
      mode = "t";
      key = "<C-l>";
      action.__raw = ''
        function()
          local cfg = vim.api.nvim_win_get_config(0)
          if cfg.relative ~= "" then
            return vim.api.nvim_replace_termcodes("<C-l>", true, false, true)
          end
          return vim.api.nvim_replace_termcodes("<C-\\><C-n><C-w>l", true, false, true)
        end
      '';
      options = {
        silent = true;
        expr = true;
        desc = "Go to Right Window";
      };
    }
    {
      mode = "t";
      key = "<C-\\>";
      action = "<C-\\><C-n>";
    }

    # Edgy toggles
    {
      mode = [
        "n"
        "x"
        "o"
        "i"
      ];
      key = "<C-x><C-[>";
      action.__raw = ''
        function()
          local ok, edgy = pcall(require, "edgy")
          if ok then edgy.toggle("left") end
        end
      '';
      options.desc = "Toggle edgy.nvim (left)";
    }
    {
      mode = [
        "n"
        "x"
        "o"
        "i"
      ];
      key = "<C-x><C-]>";
      action.__raw = ''
        function()
          local ok, edgy = pcall(require, "edgy")
          if ok then edgy.toggle("right") end
        end
      '';
      options.desc = "Toggle edgy.nvim (right)";
    }
    {
      mode = [
        "n"
        "x"
        "o"
        "i"
      ];
      key = "<C-x><C-'>";
      action.__raw = ''
        function()
          local ok, edgy = pcall(require, "edgy")
          if ok then edgy.toggle("bottom") end
        end
      '';
      options.desc = "Toggle edgy.nvim (bottom)";
    }

    # which-key keymaps
    {
      mode = "n";
      key = "<leader>?";
      action.__raw = "function() require('which-key').show({ global = false }) end";
      options.desc = "Buffer Keymaps (which-key)";
    }
    {
      mode = "n";
      key = "<c-w><space>";
      action.__raw = ''function() require("which-key").show({ keys = "<c-w>", loop = true }) end'';
      options.desc = "Window Hydra Mode (which-key)";
    }

    # Leap keymaps
    {
      mode = [
        "n"
        "x"
        "o"
      ];
      key = "s";
      action = "<Plug>(leap-forward)";
      options.desc = "Leap Forward to";
    }
    {
      mode = [
        "n"
        "x"
        "o"
      ];
      key = "ы";
      action = "<Plug>(leap-forward)";
      options.desc = "Leap Forward to";
    }
    {
      mode = [
        "n"
        "x"
        "o"
      ];
      key = "S";
      action = "<Plug>(leap-backward)";
      options.desc = "Leap Backward to";
    }
    {
      mode = [
        "n"
        "x"
        "o"
      ];
      key = "Ы";
      action = "<Plug>(leap-backward)";
      options.desc = "Leap Backward to";
    }
    {
      mode = [
        "n"
        "x"
        "o"
      ];
      key = "gs";
      action = "<Plug>(leap-from-window)";
      options.desc = "Leap from Windows";
    }

    # grug-far keymap
    {
      mode = [
        "n"
        "x"
      ];
      key = "<leader>sr";
      action.__raw = ''
        function()
          local grug = require("grug-far")
          local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
          grug.open({
            transient = true,
            prefills = {
              filesFilter = ext and ext ~= "" and "*." .. ext or nil,
            },
          })
        end
      '';
      options.desc = "Search and Replace";
    }

    # Noice keymaps
    {
      mode = "c";
      key = "<S-CR>";
      action.__raw = "function() require('noice').redirect(vim.fn.getcmdline()) end";
      options.desc = "Redirect Cmdline";
    }
    {
      mode = "n";
      key = "<leader>snl";
      action.__raw = "function() require('noice').cmd('last') end";
      options.desc = "Noice Last Message";
    }
    {
      mode = "n";
      key = "<leader>snh";
      action.__raw = "function() require('noice').cmd('history') end";
      options.desc = "Noice History";
    }
    {
      mode = "n";
      key = "<leader>sna";
      action.__raw = "function() require('noice').cmd('all') end";
      options.desc = "Noice All";
    }
    {
      mode = "n";
      key = "<leader>snd";
      action.__raw = "function() require('noice').cmd('dismiss') end";
      options.desc = "Dismiss All";
    }
    {
      mode = "n";
      key = "<leader>snt";
      action.__raw = "function() require('noice').cmd('pick') end";
      options.desc = "Noice Picker";
    }
    {
      mode = [
        "i"
        "n"
        "s"
      ];
      key = "<c-f>";
      action.__raw = "function() if not require('noice.lsp').scroll(4) then return '<c-f>' end end";
      options = {
        silent = true;
        expr = true;
        desc = "Scroll Forward";
      };
    }
    {
      mode = [
        "i"
        "n"
        "s"
      ];
      key = "<c-b>";
      action.__raw = "function() if not require('noice.lsp').scroll(-4) then return '<c-b>' end end";
      options = {
        silent = true;
        expr = true;
        desc = "Scroll Backward";
      };
    }

    # Snacks picker keymaps
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

    # Git keymaps
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

    # Search keymaps
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

    # Comment helpers (gco / gcO)
    {
      mode = "n";
      key = "gco";
      action.__raw = ''
        function()
          local cs = vim.bo.commentstring
          local pre = "# "
          if cs and cs ~= "" and cs:find("%%s") then
            pre = cs:match("^(.-)%%s") or ""
            pre = pre:gsub("%s+$", "")
            if pre ~= "" then pre = pre .. " " end
          end
          local row = vim.api.nvim_win_get_cursor(0)[1]
          vim.api.nvim_buf_set_lines(0, row, row, true, { pre })
          vim.api.nvim_win_set_cursor(0, { row + 1, #pre })
          vim.cmd("startinsert!")
        end
      '';
      options.desc = "Add Comment Below";
    }
    {
      mode = "n";
      key = "gcO";
      action.__raw = ''
        function()
          local cs = vim.bo.commentstring
          local pre = "# "
          if cs and cs ~= "" and cs:find("%%s") then
            pre = cs:match("^(.-)%%s") or ""
            pre = pre:gsub("%s+$", "")
            if pre ~= "" then pre = pre .. " " end
          end
          local row = vim.api.nvim_win_get_cursor(0)[1]
          vim.api.nvim_buf_set_lines(0, row - 1, row - 1, true, { pre })
          vim.api.nvim_win_set_cursor(0, { row, #pre })
          vim.cmd("startinsert!")
        end
      '';
      options.desc = "Add Comment Above";
    }

    # Location list / Quickfix list toggles
    {
      mode = "n";
      key = "<leader>xl";
      action.__raw = ''
        function()
          for _, win in ipairs(vim.fn.getwininfo()) do
            if win.loclist == 1 then
              vim.cmd("lclose")
              return
            end
          end
          vim.cmd("lopen")
        end
      '';
      options.desc = "Location List";
    }
    {
      mode = "n";
      key = "<leader>xq";
      action.__raw = ''
        function()
          for _, win in ipairs(vim.fn.getwininfo()) do
            if win.quickfix == 1 and win.loclist == 0 then
              vim.cmd("cclose")
              return
            end
          end
          vim.cmd("copen")
        end
      '';
      options.desc = "Quickfix List";
    }

    # VCSigns
    {
      mode = "n";
      key = "[h";
      action.__raw = ''function() require("vcsigns.actions").hunk_prev(0, vim.v.count1) end'';
      options.desc = "Prev hunk";
    }
    {
      mode = "n";
      key = "]h";
      action.__raw = ''function() require("vcsigns.actions").hunk_next(0, vim.v.count1) end'';
      options.desc = "Next hunk";
    }
    {
      mode = "n";
      key = "[H";
      action.__raw = ''function() require("vcsigns.actions").hunk_prev(0, 9999) end'';
      options.desc = "First hunk";
    }
    {
      mode = "n";
      key = "]H";
      action.__raw = ''function() require("vcsigns.actions").hunk_next(0, 9999) end'';
      options.desc = "Last hunk";
    }
    {
      mode = "n";
      key = "[r";
      action.__raw = ''function() require("vcsigns.actions").target_older_commit(0, vim.v.count1) end'';
      options.desc = "Target older revision";
    }
    {
      mode = "n";
      key = "]r";
      action.__raw = ''function() require("vcsigns.actions").target_newer_commit(0, vim.v.count1) end'';
      options.desc = "Target newer revision";
    }
    {
      mode = "n";
      key = "<leader>ju";
      action.__raw = ''function() require("vcsigns.actions").hunk_undo(0) end'';
      options.desc = "Undo hunks under cursor";
    }
    {
      mode = [ "v" ];
      key = "<leader>ju";
      action.__raw = ''function() require("vcsigns.actions").hunk_undo(0) end'';
      options.desc = "Undo hunks in range";
    }
    {
      mode = "n";
      key = "<leader>uj";
      action.__raw = ''function() require("vcsigns.actions").toggle_hunk_diff(0) end'';
      options.desc = "Toggle inline hunk diff";
    }
    {
      mode = "n";
      key = "<leader>jf";
      action.__raw = ''function() require("vcsigns.fold").toggle(0) end'';
      options.desc = "Fold outside hunks";
    }
  ];

  # LSP-only keymaps (applied on LSP attach).
  # See: https://nix-community.github.io/nixvim/lsp/keymaps/index.html
  programs.nixvim.lsp.keymaps = [
    {
      mode = "n";
      key = "<leader>cl";
      action = "<cmd>LspInfo<cr>";
      options.desc = "Lsp Info";
    }
    {
      mode = "n";
      key = "gd";
      lspBufAction = "definition";
      options.desc = "Goto Definition";
    }
    {
      mode = "n";
      key = "gr";
      lspBufAction = "references";
      options.desc = "References";
    }
    {
      mode = "n";
      key = "gI";
      lspBufAction = "implementation";
      options.desc = "Goto Implementation";
    }
    {
      mode = "n";
      key = "gy";
      lspBufAction = "type_definition";
      options.desc = "Goto Type Definition";
    }
    {
      mode = "n";
      key = "gD";
      lspBufAction = "declaration";
      options.desc = "Goto Declaration";
    }
    {
      mode = "n";
      key = "K";
      lspBufAction = "hover";
      options.desc = "Hover";
    }
    {
      mode = "n";
      key = "gK";
      lspBufAction = "signature_help";
      options.desc = "Signature Help";
    }
    {
      mode = "i";
      key = "<C-k>";
      lspBufAction = "signature_help";
      options.desc = "Signature Help";
    }
    {
      mode = [
        "n"
        "x"
      ];
      key = "<leader>ca";
      lspBufAction = "code_action";
      options.desc = "Code Action";
    }
    {
      mode = [
        "n"
        "x"
      ];
      key = "<leader>cc";
      action.__raw = ''
        function()
          local ok = pcall(function() vim.lsp.codelens.run() end)
          if not ok then
            vim.notify("Codelens not supported in this Neovim/LSP setup", vim.log.levels.WARN)
          end
        end
      '';
      options.desc = "Run Codelens";
    }
    {
      mode = "n";
      key = "<leader>cC";
      action.__raw = ''
        function()
          local ok = pcall(function() vim.lsp.codelens.refresh() end)
          if not ok then
            vim.notify("Codelens not supported in this Neovim/LSP setup", vim.log.levels.WARN)
          end
        end
      '';
      options.desc = "Refresh & Display Codelens";
    }
    {
      mode = "n";
      key = "<leader>cR";
      action.__raw = ''
        function()
          local bufnr = 0
          local old = vim.api.nvim_buf_get_name(bufnr)
          if not old or old == "" then
            vim.notify("No file name for current buffer", vim.log.levels.WARN)
            return
          end

          vim.ui.input({ prompt = "Rename file to: ", default = old }, function(new)
            if not new or new == "" or new == old then return end

            local dir = vim.fn.fnamemodify(new, ":h")
            if dir and dir ~= "" and dir ~= "." then
              pcall(vim.fn.mkdir, dir, "p")
            end

            local oldUri = vim.uri_from_fname(old)
            local newUri = vim.uri_from_fname(new)
            local params = { files = { { oldUri = oldUri, newUri = newUri } } }

            -- Best-effort: ask LSP for workspace edits before renaming.
            local pending_edits = {}
            for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
              if client.supports_method and client:supports_method("workspace/willRenameFiles") then
                local res = client.request_sync("workspace/willRenameFiles", params, 1000, bufnr)
                if res and res.result and res.result.workspaceEdit then
                  table.insert(pending_edits, { client = client, edit = res.result.workspaceEdit })
                end
              end
            end

            local rc = vim.fn.rename(old, new)
            if rc ~= 0 then
              vim.notify("Rename failed (vim.fn.rename exit code: " .. tostring(rc) .. ")", vim.log.levels.ERROR)
              return
            end

            -- Update current buffer to point at the new path.
            vim.api.nvim_buf_set_name(bufnr, new)
            vim.cmd("silent! edit!")

            -- Apply workspace edits (if any).
            for _, item in ipairs(pending_edits) do
              pcall(vim.lsp.util.apply_workspace_edit, item.edit, item.client.offset_encoding)
            end

            -- Notify LSP after rename (if supported).
            for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
              if client.supports_method and client:supports_method("workspace/didRenameFiles") then
                client.notify("workspace/didRenameFiles", params)
              end
            end
          end)
        end
      '';
      options.desc = "Rename File";
    }
    {
      mode = "n";
      key = "<leader>cr";
      lspBufAction = "rename";
      options.desc = "Rename";
    }
    {
      mode = "n";
      key = "<leader>cA";
      action.__raw = ''
        function()
          vim.lsp.buf.code_action({
            context = { only = { "source" } },
            apply = true,
          })
        end
      '';
      options.desc = "Source Action";
    }
    {
      mode = "n";
      key = "]]";
      action.__raw = ''
        function()
          local ok, illuminate = pcall(require, "illuminate")
          if ok and illuminate and illuminate.goto_next_reference then
            illuminate.goto_next_reference(false)
            return
          end
          local word = vim.fn.expand("<cword>")
          if not word or word == "" then return end
          local pat = "\\V\\<" .. vim.fn.escape(word, "\\") .. "\\>"
          vim.fn.search(pat, "W")
        end
      '';
      options.desc = "Next Reference";
    }
    {
      mode = "n";
      key = "[[";
      action.__raw = ''
        function()
          local ok, illuminate = pcall(require, "illuminate")
          if ok and illuminate and illuminate.goto_prev_reference then
            illuminate.goto_prev_reference(false)
            return
          end
          local word = vim.fn.expand("<cword>")
          if not word or word == "" then return end
          local pat = "\\V\\<" .. vim.fn.escape(word, "\\") .. "\\>"
          vim.fn.search(pat, "bW")
        end
      '';
      options.desc = "Prev Reference";
    }
    {
      mode = "n";
      key = "<A-n>";
      action.__raw = ''
        function()
          local ok, illuminate = pcall(require, "illuminate")
          if ok and illuminate and illuminate.goto_next_reference then
            illuminate.goto_next_reference(false)
            return
          end
          local word = vim.fn.expand("<cword>")
          if not word or word == "" then return end
          local pat = "\\V\\<" .. vim.fn.escape(word, "\\") .. "\\>"
          vim.fn.search(pat, "W")
        end
      '';
      options.desc = "Next Reference";
    }
    {
      mode = "n";
      key = "<A-p>";
      action.__raw = ''
        function()
          local ok, illuminate = pcall(require, "illuminate")
          if ok and illuminate and illuminate.goto_prev_reference then
            illuminate.goto_prev_reference(false)
            return
          end
          local word = vim.fn.expand("<cword>")
          if not word or word == "" then return end
          local pat = "\\V\\<" .. vim.fn.escape(word, "\\") .. "\\>"
          vim.fn.search(pat, "bW")
        end
      '';
      options.desc = "Prev Reference";
    }
    {
      mode = "n";
      key = "<leader>ss";
      action.__raw = ''
        function()
          local ok, snacks = pcall(require, "snacks")
          if ok and snacks and snacks.picker and snacks.picker.lsp_symbols then
            snacks.picker.lsp_symbols()
            return
          end
          vim.lsp.buf.document_symbol()
        end
      '';
      options.desc = "LSP Symbols";
    }
    {
      mode = "n";
      key = "<leader>sS";
      action.__raw = ''
        function()
          local ok, snacks = pcall(require, "snacks")
          if ok and snacks and snacks.picker and snacks.picker.lsp_workspace_symbols then
            snacks.picker.lsp_workspace_symbols()
            return
          end
          vim.lsp.buf.workspace_symbol()
        end
      '';
      options.desc = "LSP Workspace Symbols";
    }
    {
      mode = "n";
      key = "gai";
      action.__raw = ''
        function()
          local ok = pcall(function() vim.lsp.buf.incoming_calls() end)
          if not ok then
            vim.notify("Incoming calls not supported in this Neovim/LSP setup", vim.log.levels.WARN)
          end
        end
      '';
      options.desc = "Calls Incoming";
    }
    {
      mode = "n";
      key = "gao";
      action.__raw = ''
        function()
          local ok = pcall(function() vim.lsp.buf.outgoing_calls() end)
          if not ok then
            vim.notify("Outgoing calls not supported in this Neovim/LSP setup", vim.log.levels.WARN)
          end
        end
      '';
      options.desc = "Calls Outgoing";
    }
    {
      mode = [
        "n"
        "x"
      ];
      key = "<leader>cf";
      lspBufAction = "format";
      options.desc = "Format";
    }
    {
      mode = "n";
      key = "<leader>cd";
      action.__raw = "function() vim.diagnostic.open_float(nil, { scope = 'line' }) end";
      options.desc = "Line Diagnostics";
    }
    {
      mode = "n";
      key = "]d";
      action.__raw = "function() vim.diagnostic.goto_next() end";
      options.desc = "Next Diagnostic";
    }
    {
      mode = "n";
      key = "[d";
      action.__raw = "function() vim.diagnostic.goto_prev() end";
      options.desc = "Prev Diagnostic";
    }
    {
      mode = "n";
      key = "]e";
      action.__raw = "function() vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR }) end";
      options.desc = "Next Error";
    }
    {
      mode = "n";
      key = "[e";
      action.__raw = "function() vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR }) end";
      options.desc = "Prev Error";
    }
    {
      mode = "n";
      key = "]w";
      action.__raw = "function() vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.WARN }) end";
      options.desc = "Next Warning";
    }
    {
      mode = "n";
      key = "[w";
      action.__raw = "function() vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.WARN }) end";
      options.desc = "Prev Warning";
    }
  ];
}
