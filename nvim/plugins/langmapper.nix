{
  pkgs,
  lib,
  options,
  ...
}:
let
  isDarwin = pkgs.stdenv.isDarwin;
  ruLayout = "ËЙЦУКЕНГШЩЗХЪ/ФЫВАПРОЛДЖЭЯЧСМИТЬБЮ,ёйцукенгшщзхъфывапролджэячсмитьбю.";
in
{
  plugins.langmapper = {
    enable = true;

    # Ensure keymap wrappers are applied early.
    autoLoad = true;
    automapping.enable = true; 
    automapping.argument = {
      buffer = true;
      global = true;
    };

    settings = {
      hack_keymap = true;

      # Use macOS input source via `macism` when available.
      os = lib.optionalAttrs isDarwin {
        Darwin.get_current_layout_id.__raw = ''
          function()
            local cmd = "macism"
            if vim.fn.executable(cmd) == 1 then
              return vim.trim(vim.fn.system(cmd))
            end
          end
        '';
      };

      # Support both common Russian layout IDs on macOS.
      layouts = {
        ru = {
          id = "com.apple.keylayout.Russian";
          layout = ruLayout;
        };
        ru_win = {
          id = "com.apple.keylayout.RussianWin";
          layout = ruLayout;
        };
      };

      use_layouts = [
        "ru"
        "ru_win"
      ];
    };
  };
}
