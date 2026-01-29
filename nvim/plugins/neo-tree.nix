{ ... }:
{
  plugins."neo-tree" = {
    enable = true;
    settings = {
      filesystem.follow_current_file.enabled = true;
      window = {
        mappings = {
          h = "close_node";
          l = "open";
        };
      };
      default_component_configs = {
        indent = {
          with_expanders = true;
          expander_collapsed = "";
          expander_expanded = "";
          expander_highlight = "NeoTreeExpander";
        };
      };
      git_status = {
        symbols = {
          unstaged = "󰄱";
          staged = "󰱒";
        };
      };
    };
  };

  keymaps = [
    {
      mode = "n";
      key = "<leader>e";
      action = "<cmd>Neotree toggle<cr>";
      options.desc = "Explorer (Neo-tree)";
    }
  ];
}
