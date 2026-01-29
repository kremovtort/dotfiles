{ ... }:
{
  plugins."grug-far" = {
    enable = true;
    settings.headerMaxWidth = 80;
  };

  keymaps = [
    {
      mode = [
        "n"
        "x"
      ];
      key = "<leader>sr";
      action.__raw = ''
        function()
          local grug = require("grug-far")
          local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
          grug.open({
            transient = true,
            prefills = {
              filesFilter = ext and ext ~= "" and "*." .. ext or nil,
            },
          })
        end
      '';
      options.desc = "Search and Replace";
    }
  ];
}
