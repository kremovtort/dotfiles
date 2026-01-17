{ inputs, ... }:
{
  imports = [ inputs.paneru.homeModules.paneru ];

  paneru = {
    enable = false;
    # Equivalent to what you would put into `~/.paneru` (See Configuration options below).
    settings = {
      options = {
        focus_follows_mouse = false;
        mouse_follows_focus = false;
        preset_column_widths = [
          0.25
          0.33
          0.5
          0.66
          0.75
          1
        ];
        animation_speed = 500000;
      };
      bindings = {
        window_focus_west = "cmd + ctrl - h";
        window_focus_east = "cmd + ctrl - l";
        window_focus_north = "cmd + ctrl - k";
        window_focus_south = "cmd + ctrl - j";
        window_swap_west = "alt + ctrl - h";
        window_swap_east = "alt + ctrl - l";
        window_swap_first = "alt + shift - h";
        window_swap_last = "alt + shift - l";
        window_center = "alt - c";
        window_resize = "alt - r";
        window_manage = "cmd + alt - t";
        window_stack = "alt + ctrl - ]";
        window_unstack = "alt + ctrl + shift - ]";
        quit = "ctrl + alt - q";
      };
    };
  };
}
