{
  enable = true;
  global.autoUpdate = false;
  onActivation = {
    autoUpdate = false;
    cleanup = "zap";
    extraFlags = [ "--verbose" ];
    upgrade = false;
  };
  brews = [
    {
      name = "arc-launcher";
      start_service = true;
      restart_service = "changed";
    }
  ];
  casks = [
    "affine"
    "karabiner-elements"
    "ollama"
    "scroll-reverser"
    "telegram-desktop"
    "visual-studio-code"
    "yandex-music"
    "zen-browser"
  ];
  taps = [
    "homebrew/services"
    {
      name = "yandex/arc";
      clone_target = "https://arc-vcs.yandex-team.ru/homebrew-tap";
    }
  ];
}