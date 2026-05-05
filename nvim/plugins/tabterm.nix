{
  plugins.tabterm = {
    enable = true;
    settings = {
      ui = {
        border = "round";
        sidebar_width = 30;
        float = {
          width = 0.90;
          height = 0.90;
        };
      };
    };
  };

  keymaps = [
    {
      mode = [
        "n"
        "t"
      ];
      key = "<C-/>";
      action.__raw = ''function() require("tabterm").toggle() end'';
      options.desc = "Toggle tab terminals";
    }
  ];
}
