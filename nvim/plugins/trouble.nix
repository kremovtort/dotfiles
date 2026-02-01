{ ... }:
{
  plugins.trouble = {
    enable = true;
    settings = {
      # Picker-like two-column diagnostics view (list + preview).
      # Layout rules:
      # - total footprint is ~0.8x0.8 of the editor size
      # - 1 column gap between the two floating borders (so they don't visually merge)
      modes.diag_picker = {
        mode = "diagnostics";
        focus = true;
        auto_preview = true;

        # Picker-style fold navigation.
        # Also disable <esc> so it doesn't cancel/close the picker-like UI.
        keys = {
          h = "fold_close";
          l = "fold_open";
          "<esc>" = false;
        };

        config.__raw = ''
          function(opts)
            local W = vim.o.columns
            local H = vim.o.lines

            local container_w = math.floor(W * 0.9)
            local container_h = math.floor(H * 0.9)

            local gap_cols = 0
            local border_cols = 2
            local border_rows = 2

            local outer_w_each = math.floor((container_w - gap_cols) / 2)
            local inner_w = math.max(20, outer_w_each - border_cols)
            local inner_h = math.max(5, container_h - border_rows)

            local left = math.floor((W - container_w) / 2)
            local top = math.floor((H - container_h) / 2)

            opts.win.size = { width = inner_w, height = inner_h }
            opts.preview.size = { width = inner_w, height = inner_h }

            -- Trouble float position is {row, col} for the inner window.
            -- Border adds 1 cell on each side.
            opts.win.position = { top + 1, left + 1 }
            opts.preview.position = { top + 1, left + outer_w_each + gap_cols + 1 }
          end
        '';

        win = {
          type = "float";
          relative = "editor";
          border = "rounded";
          title = "Diagnostics";
          title_pos = "center";
        };

        preview = {
          type = "float";
          relative = "editor";
          border = "rounded";
          title = "Preview";
          title_pos = "center";
          zindex = 200;
          wo = {
            number = true;
            relativenumber = false;
            signcolumn = "no";
          };
        };
      };

      modes.diag_picker_buffer = {
        mode = "diag_picker";
        filter = {
          buf = 0;
        };
      };
    };

    luaConfig.post = ''
      do
        local group = vim.api.nvim_create_augroup("kremovtort_trouble_diag_picker_backdrop", { clear = true })

        local state = vim.g._kremovtort_trouble_backdrop or {}
        vim.g._kremovtort_trouble_backdrop = state

        local function backdrop_valid()
          return state.win and vim.api.nvim_win_is_valid(state.win)
        end

        local function any_diag_picker_open()
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            local t = vim.w[win].trouble
            if t and t.mode == "diag_picker" then
              return true
            end
          end
          return false
        end

        local function backdrop_open()
          if backdrop_valid() then
            return
          end

          local buf = state.buf
          if not (buf and vim.api.nvim_buf_is_valid(buf)) then
            buf = vim.api.nvim_create_buf(false, true)
            state.buf = buf
            vim.bo[buf].bufhidden = "wipe"
            vim.bo[buf].buftype = "nofile"
            vim.bo[buf].modifiable = false
          end

          -- A simple dim backdrop. Works well with dark themes.
          pcall(vim.api.nvim_set_hl, 0, "TroubleBackdrop", { bg = "#000000" })

          local win = vim.api.nvim_open_win(buf, false, {
            relative = "editor",
            row = 0,
            col = 0,
            width = vim.o.columns,
            height = vim.o.lines,
            style = "minimal",
            focusable = false,
            zindex = 1,
            noautocmd = true,
          })

          state.win = win
          vim.wo[win].winblend = 60
          vim.wo[win].winhighlight = "Normal:TroubleBackdrop"
        end

        local function backdrop_close()
          if backdrop_valid() then
            pcall(vim.api.nvim_win_close, state.win, true)
          end
          state.win = nil
          if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
            pcall(vim.api.nvim_buf_delete, state.buf, { force = true })
          end
          state.buf = nil
        end

        local function sync_backdrop()
          if any_diag_picker_open() then
            backdrop_open()
            if backdrop_valid() then
              pcall(vim.api.nvim_win_set_config, state.win, {
                relative = "editor",
                row = 0,
                col = 0,
                width = vim.o.columns,
                height = vim.o.lines,
              })
            end
          else
            backdrop_close()
          end
        end

        vim.api.nvim_create_autocmd({ "WinNew", "WinEnter", "WinClosed" }, {
          group = group,
          callback = function()
            vim.schedule(sync_backdrop)
          end,
        })
        vim.api.nvim_create_autocmd("VimResized", {
          group = group,
          callback = function()
            vim.schedule(sync_backdrop)
          end,
        })
      end
    '';
  };

  keymaps = [
    {
      mode = "n";
      key = "<leader>xx";
      action = "<cmd>Trouble diag_picker toggle<cr>";
      options.desc = "Diagnostics (Trouble)";
    }
    {
      mode = "n";
      key = "<leader>xX";
      action = "<cmd>Trouble diag_picker_buffer toggle<cr>";
      options.desc = "Buffer Diagnostics (Trouble)";
    }
    {
      mode = "n";
      key = "<leader>cs";
      action = "<cmd>Trouble symbols toggle<cr>";
      options.desc = "Symbols (Trouble)";
    }
    {
      mode = "n";
      key = "<leader>cS";
      action = "<cmd>Trouble lsp toggle<cr>";
      options.desc = "LSP references/definitions/... (Trouble)";
    }
    {
      mode = "n";
      key = "<leader>xL";
      action = "<cmd>Trouble loclist toggle<cr>";
      options.desc = "Location List (Trouble)";
    }
    {
      mode = "n";
      key = "<leader>xQ";
      action = "<cmd>Trouble qflist toggle<cr>";
      options.desc = "Quickfix List (Trouble)";
    }
    {
      mode = "n";
      key = "[q";
      action.__raw = ''
        function()
          if require("trouble").is_open() then
            require("trouble").prev({ skip_groups = true, jump = true })
          else
            local ok, err = pcall(vim.cmd.cprev)
            if not ok then
              vim.notify(err, vim.log.levels.ERROR)
            end
          end
        end
      '';
      options.desc = "Previous Trouble/Quickfix Item";
    }
    {
      mode = "n";
      key = "]q";
      action.__raw = ''
        function()
          if require("trouble").is_open() then
            require("trouble").next({ skip_groups = true, jump = true })
          else
            local ok, err = pcall(vim.cmd.cnext)
            if not ok then
              vim.notify(err, vim.log.levels.ERROR)
            end
          end
        end
      '';
      options.desc = "Next Trouble/Quickfix Item";
    }
  ];
}
