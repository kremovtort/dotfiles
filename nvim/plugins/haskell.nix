{
  plugins.haskell-tools = {
    enable = true;
    settings.hls.default_settings.haskell.plugin.importLens = {
      globalOn = false;
      codeActionsOn = false;
      codeLensOn = false;
    };
  };

  plugins.haskell-scope-highlighting.enable = false;
}
