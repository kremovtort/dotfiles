{ ... }:
{
  colorschemes.catppuccin.settings.integrations.leap = true;

  plugins.leap.enable = true;

  # Flit (f/t motions with leap)
  plugins.flit = {
    enable = true;
    settings.labeled_modes = "nx";
  };

  keymaps = [
    {
      mode = [
        "n"
        "x"
        "o"
      ];
      key = "s";
      action = "<Plug>(leap-forward)";
      options.desc = "Leap Forward to";
    }
    {
      mode = [
        "n"
        "x"
        "o"
      ];
      key = "ы";
      action = "<Plug>(leap-forward)";
      options.desc = "Leap Forward to";
    }
    {
      mode = [
        "n"
        "x"
        "o"
      ];
      key = "S";
      action = "<Plug>(leap-backward)";
      options.desc = "Leap Backward to";
    }
    {
      mode = [
        "n"
        "x"
        "o"
      ];
      key = "Ы";
      action = "<Plug>(leap-backward)";
      options.desc = "Leap Backward to";
    }
    {
      mode = [
        "n"
        "x"
        "o"
      ];
      key = "gs";
      action = "<Plug>(leap-from-window)";
      options.desc = "Leap from Windows";
    }
  ];
}
