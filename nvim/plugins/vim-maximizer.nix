{ pkgs, nvimInputs, ... }:
{
  extraPlugins = [
    (pkgs.vimUtils.buildVimPlugin {
      pname = "vim-maximizer";
      version = "unstable-2024-12-01";

      src = nvimInputs.plugins-vim-maximizer;
    })
  ];

  keymaps = [
    {
      mode = "n";
      key = "<leader>z";
      action = "<cmd>MaximizerToggle<CR>";
      options = {
        desc = "Toggle maximize window";
      };
    }
  ];
}
