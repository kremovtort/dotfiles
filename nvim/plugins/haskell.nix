{ ... }:
{
  plugins."haskell-tools" = {
    enable = true;
    settings = {
      hls = {
        default_settings.haskell = {
          formatting_provider = "fourmolu";
        };
      };
    };
  };

  plugins."haskell-scope-highlighting".enable = false;
}
