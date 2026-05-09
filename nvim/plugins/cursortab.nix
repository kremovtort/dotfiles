{
  pkgs,
  lib,
  nvimInputs,
  ...
}:
let
  cursortabSrc = nvimInputs.plugins-cursortab-nvim;

  cursortabServer = pkgs.buildGoModule {
    pname = "cursortab-nvim-server";
    version = "unstable";
    src = cursortabSrc + "/server";
    vendorHash = "sha256-4S14Vm2Ju084uxB2Zlku4z5AmIZkNZkQpiNgYrcqIbg=";
    subPackages = [ "." ];
  };

  cursortabNvim = pkgs.vimUtils.buildVimPlugin {
    name = "cursortab-nvim";
    src = cursortabSrc;

    postInstall = ''
      install -Dm755 ${cursortabServer}/bin/cursortab $out/server/cursortab
    '';
  };
in
{
  extraPlugins = [ cursortabNvim ];

  extraConfigLua = lib.mkAfter ''
    require("cursortab").setup({
      provider = {
        type = "mercuryapi",
        api_key_env = "MERCURY_AI_TOKEN",
      },
    })
  '';

  keymaps = [
    {
      mode = "n";
      key = "<leader>aC";
      action = "<cmd>CursortabToggle<cr>";
      options.desc = "Toggle Cursortab";
    }
    {
      mode = "n";
      key = "<leader>aT";
      action = "<cmd>CursortabStatus<cr>";
      options.desc = "Cursortab Status";
    }
  ];
}
