{ lib, ... }:
{
  dependencies.opencode.enable = lib.mkForce false;

  plugins.opencode = {
    enable = true;
    autoLoad = true;
    settings = {
      provider.enabled = "snacks";

      keymap_prefix = "<leader>a";

      default_global_keymaps = false;
    };
  };

  autoCmd = [
    # When OpenCode UI opens, move focus to its input window.
    {
      event = "FileType";
      group = "kremovtort_autocmds";
      pattern = "opencode";
      callback.__raw = ''
        function(ev)
          vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(ev.buf) then return end
            local wins = vim.fn.win_findbuf(ev.buf)
            local win = wins[1]
            if win and vim.api.nvim_win_is_valid(win) then
              if vim.api.nvim_get_current_win() ~= win then
                vim.api.nvim_set_current_win(win)
              end
              vim.cmd("startinsert")
            end
          end)
        end
      '';
    }

    # Disable mouse/trackpad scrolling in opencode terminal window
    {
      event = "FileType";
      group = "kremovtort_autocmds";
      pattern = "opencode_terminal";
      callback.__raw = ''
        function(ev)
          local modes = { "n", "i", "v", "t" }
          for _, key in ipairs({
            "<ScrollWheelUp>",
            "<ScrollWheelDown>",
            "<S-ScrollWheelUp>",
            "<S-ScrollWheelDown>",
            "<C-ScrollWheelUp>",
            "<C-ScrollWheelDown>",
            "<ScrollWheelLeft>",
            "<ScrollWheelRight>",
          }) do
            pcall(vim.keymap.del, modes, key, { buffer = ev.buf })
          end
        end
      '';
    }
  ];

  keymaps = [
    {
      mode = [
        "n"
        "x"
      ];
      key = "<leader>aa";
      action.__raw = ''function() require("opencode").ask("@this: ", { submit = true }) end'';
      options.desc = "Ask opencode…";
    }
    {
      mode = [
        "n"
        "x"
      ];
      key = "<leader>ax";
      action.__raw = ''function() require("opencode").select() end'';
      options.desc = "Execute opencode action…";
    }
    {
      mode = [
        "n"
        "t"
        "x"
      ];
      key = "<D-k>";
      action.__raw = ''
        function()
          require("opencode").toggle()

          -- opencode opens its UI in a side window; ensure we enter it
          -- instead of staying in the current window.
          vim.schedule(function()
            local function focus_ft(ft)
              for _, win in ipairs(vim.api.nvim_list_wins()) do
                local buf = vim.api.nvim_win_get_buf(win)
                if vim.bo[buf].filetype == ft then
                  vim.api.nvim_set_current_win(win)
                  vim.cmd("startinsert")
                  return true
                end
              end
              return false
            end

            if focus_ft("opencode") then return end
            if focus_ft("opencode_terminal") then return end
            focus_ft("opencode_output")
          end)
        end
      '';
      options.desc = "Toggle opencode…";
    }
    {
      mode = [
        "n"
        "v"
        "x"
      ];
      key = "go";
      action.__raw = ''function() return require("opencode").operator("@this ") end'';
      options.desc = "Add range to opencode";
      options.expr = true;
    }
    {
      mode = "n";
      key = "goo";
      action.__raw = ''function() return require("opencode").operator("@this ") .. "_" end'';
      options.desc = "Add line to opencode";
      options.expr = true;
    }
    {
      mode = "n";
      key = "<S-C-u>";
      action.__raw = ''function() require("opencode").command("session.half.page.up") end'';
      options.desc = "Scroll opencode up";
    }
    {
      mode = "n";
      key = "<S-C-d>";
      action.__raw = ''function() require("opencode").command("session.half.page.down") end'';
      options.desc = "Scroll opencode down";
    }
  ];
}
