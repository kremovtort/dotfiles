{ ... }:
{
  programs.nixvim = {
    autoGroups.kremovtort_autocmds.clear = true;

    autoCmd = [
      {
        event = "TextYankPost";
        group = "kremovtort_autocmds";
        callback.__raw = ''
          function()
            vim.highlight.on_yank({ timeout = 200 })
          end
        '';
      }
      {
        event = "VimResized";
        group = "kremovtort_autocmds";
        callback.__raw = ''
          function()
            vim.cmd("tabdo wincmd =")
          end
        '';
      }

      # Terminal buffer settings
      {
        event = "TermOpen";
        group = "kremovtort_autocmds";
        callback.__raw = ''
          function()
            vim.opt_local.number = false
            vim.opt_local.relativenumber = false
            vim.opt_local.signcolumn = "no"
            vim.cmd("startinsert")
          end
        '';
      }
      {
        event = "BufEnter";
        group = "kremovtort_autocmds";
        pattern = "term://*";
        callback.__raw = ''
          function()
            vim.opt_local.number = false
            vim.opt_local.relativenumber = false
            vim.cmd("startinsert")
          end
        '';
      }

      # Cursor-agent buffer settings
      {
        event = "BufEnter";
        group = "kremovtort_autocmds";
        pattern = "term://*";
        callback.__raw = ''
          function()
            if vim.b.cursor_agent then
              vim.opt_local.scrolloff = 0
              vim.cmd("startinsert")
            end
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
            local opts = { buffer = ev.buf, silent = true, nowait = true }
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
              vim.keymap.set({ "n", "i", "v", "t" }, key, "<Nop>", opts)
            end
          end
        '';
      }
    ];
  };
}
