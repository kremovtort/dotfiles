{ ... }:
{
  plugins."mini-pairs" = {
    enable = true;
    autoLoad = true;
    settings = {
      modes = {
        insert = true;
        command = true;
        terminal = false;
      };
    };
  };
}
