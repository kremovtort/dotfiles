{
  pkgs,
  nvimInputs,
  ...
}:
let
  haskellTools = pkgs.vimUtils.buildVimPlugin {
    name = "haskell-tools-nvim";
    src = nvimInputs.plugins-haskell-tools-nvim;
    dependencies = with pkgs.vimPlugins; [
      plenary-nvim
      telescope-nvim
    ];
  };
in
{
  plugins.haskell-tools = {
    enable = true;
    package = haskellTools;
    settings.hls.default_settings.haskell.plugin.importLens = {
      globalOn = false;
      codeActionsOn = false;
      codeLensOn = false;
    };
  };

  plugins."haskell-scope-highlighting".enable = false;
}
