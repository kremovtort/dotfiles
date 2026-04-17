{ lib, ... }:
{
  extraConfigLua = lib.mkAfter ''
    if vim.g.neovide then
      local function paste()
        vim.api.nvim_paste(vim.fn.getreg("+"), true, -1)
      end

      vim.keymap.set({ "n", "i", "v", "c", "t" }, "<D-v>", paste, {
        silent = true,
        desc = "Paste from system clipboard",
      })
    end
  '';

  keymaps = [
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

    # Tab navigation
    {
      mode = "n";
      key = "gtn";
      action = "<cmd>tabnew<cr>";
      options.desc = "New Tab";
    }
    {
      mode = "n";
      key = "gtd";
      action = "<cmd>tabclose<cr>";
      options.desc = "Close Tab";
    }
    {
      mode = "n";
      key = "g1";
      action = "1gt";
      options.desc = "Go to Tab 1";
    }
    {
      mode = "n";
      key = "g2";
      action = "2gt";
      options.desc = "Go to Tab 2";
    }
    {
      mode = "n";
      key = "g3";
      action = "3gt";
      options.desc = "Go to Tab 3";
    }
    {
      mode = "n";
      key = "g4";
      action = "4gt";
      options.desc = "Go to Tab 4";
    }
    {
      mode = "n";
      key = "g5";
      action = "5gt";
      options.desc = "Go to Tab 5";
    }
    {
      mode = "n";
      key = "g6";
      action = "6gt";
      options.desc = "Go to Tab 6";
    }
    {
      mode = "n";
      key = "g7";
      action = "7gt";
      options.desc = "Go to Tab 7";
    }
    {
      mode = "n";
      key = "g8";
      action = "8gt";
      options.desc = "Go to Tab 8";
    }
    {
      mode = "n";
      key = "g9";
      action = "9gt";
      options.desc = "Go to Tab 9";
    }

    # Buffer delete
    {
      mode = "n";
      key = "<leader>bd";
      action.__raw = "function() require('snacks').bufdelete() end";
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
    {
      mode = "n";
      key = "gx";
      action.__raw = ''
        function()
          local target = vim.fn.expand("<cfile>")
          if target == "" then
            target = vim.fn.expand("<cWORD>")
          end

          target = target
            :gsub("^%(", "")
            :gsub("%)$", "")
            :gsub("^<", "")
            :gsub(">$", "")
            :gsub("[.,;:]+$", "")

          if target == "" then
            vim.notify("No link under cursor", vim.log.levels.WARN)
            return
          end

          local opener = vim.fn.has("mac") == 1 and "open" or "xdg-open"
          if vim.fn.executable(opener) ~= 1 then
            vim.notify("No system opener found for links", vim.log.levels.ERROR)
            return
          end

          vim.fn.jobstart({ opener, target }, { detach = true })
        end
      '';
      options.desc = "Open Link";
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
      action.__raw = "function() vim.o.showtabline = vim.o.showtabline == 0 and 1 or 0 end";
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

  ];

}
