{
  pkgs,
  lib,
  nvimInputs,
  ...
}:
let
  seeker = pkgs.vimUtils.buildVimPlugin {
    name = "seeker-nvim";
    src = nvimInputs.plugins-seeker-nvim;
    dependencies = with pkgs.vimPlugins; [ snacks-nvim ];
  };
in
{
  extraPlugins = [ seeker ];

  extraConfigLua = lib.mkAfter ''
    require("seeker").setup({
      picker_provider = "snacks",
      toggle_key = "<C-e>",
      picker_opts = {
        follow = true,
      },
    })
  '';

  keymaps = [
    {
      mode = "n";
      key = "<leader><leader>";
      action = "<cmd>Seeker<cr>";
      options.desc = "Seeker";
    }
    {
      mode = "n";
      key = "<leader>ff";
      action = "<cmd>Seeker<cr>";
      options.desc = "Seeker";
    }
    {
      mode = "n";
      key = "<leader>fg";
      action = "<cmd>Seeker git_files<cr>";
      options.desc = "Seeker Git Files";
    }
    {
      mode = "n";
      key = "<leader>sg";
      action = "<cmd>Seeker grep<cr>";
      options.desc = "Seeker Grep";
    }
  ];
}
