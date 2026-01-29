{ ... }:
{
  plugins.hunk = {
    enable = true;
    settings = {
      keys = {
        global = {
          quit = [ "q" ];
          accept = [ "<leader><Cr>" ];
          focus_tree = [ "<leader>e" ];
        };
        tree = {
          expand_node = [
            "l"
            "<Right>"
          ];
          collapse_node = [
            "h"
            "<Left>"
          ];
          open_file = [ "<Cr>" ];
          toggle_file = [ "a" ];
        };
        diff = {
          toggle_hunk = [ "A" ];
          toggle_line = [ "a" ];
          toggle_line_pair = [ "s" ];
          prev_hunk = [ "[h" ];
          next_hunk = [ "]h" ];
          toggle_focus = [ "<Tab>" ];
        };
      };
      ui = {
        tree = {
          mode = "nested";
          width = 35;
        };
        layout = "vertical";
      };
      icons = {
        enable_file_icons = true;
        selected = "󰡖";
        deselected = "";
        partially_selected = "󰛲";
        folder_open = "";
        folder_closed = "";
        expanded = "";
        collapsed = "";
      };
    };
  };
}
