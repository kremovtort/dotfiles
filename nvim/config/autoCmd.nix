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
        function(ev)
          vim.opt_local.number = false
          vim.opt_local.relativenumber = false

          -- Avoid forcing insert mode when a plugin briefly switches buffers.
          -- Only enter insert if we are still in this terminal buffer
          -- on the next tick (typical for user-driven :term enters).
          vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(ev.buf) then return end
            if vim.api.nvim_get_current_buf() ~= ev.buf then return end

            vim.cmd("startinsert")
          end)
        end
      '';
    }
  ];
}
