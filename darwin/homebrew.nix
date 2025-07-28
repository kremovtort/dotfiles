{
  enable = true;
  global.autoUpdate = false;
  onActivation = {
    autoUpdate = false;
    extraFlags = [ "--verbose" ];
    upgrade = false;
  };
  brews = [
    "swi-prolog"
    {
      name = "arc-launcher";
      start_service = true;
      restart_service = "changed";
    }
  ];
  taps = [
    "homebrew/services"
    {
      name = "yandex/arc";
      clone_target = "https://arc-vcs.yandex-team.ru/homebrew-tap";
    }
  ];
}
