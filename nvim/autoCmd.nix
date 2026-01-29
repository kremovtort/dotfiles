{ ... }:
{
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
}
