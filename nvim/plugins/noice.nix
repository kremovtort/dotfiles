{ ... }:
{
  plugins.noice = {
    enable = true;
    settings = {
      lsp.override = {
        "vim.lsp.util.convert_input_to_markdown_lines" = true;
        "vim.lsp.util.stylize_markdown" = true;
        "cmp.entry.get_documentation" = true;
      };
      routes = [
        {
          filter = {
            event = "msg_show";
            any = [
              { find = "%d+L, %d+B"; }
              { find = "; after #%d+"; }
              { find = "; before #%d+"; }
            ];
          };
          view = "mini";
        }
      ];
      presets = {
        bottom_search = true;
        command_palette = true;
        long_message_to_split = true;
      };
    };
  };

  keymaps = [
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
        desc = "Scroll Back";
      };
    }
  ];
}
