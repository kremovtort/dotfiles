{ ... }:
{
  plugins."auto-session" = {
    enable = true;
    settings = {
      auto_restore = false;
      auto_save = true;
      bypass_save_filetypes = [
        "snacks_dashboard"
        "dashboard"
        "alpha"
      ];
      suppressed_dirs = [
        "~/"
        "~/Projects"
        "~/Downloads"
        "/"
      ];
      args_allow_single_directory = true;
      args_allow_files_auto_save = false;
    };
  };
}
