{
  pkgs,
  lib,
  ...
}:
let
  isDarwin = pkgs.stdenv.isDarwin;
  ruLayout = "ËЙЦУКЕНГШЩЗХЪ/ФЫВАПРОЛДЖЭЯЧСМИТЬБЮ,ёйцукенгшщзхъфывапролджэячсмитьбю.";
in
{
  # Built-in Neovim langmap (for motions/commands).
  extraConfigLuaPre = lib.mkBefore ''
    local function escape(str)
      local escape_chars = [[;,."|\]]
      return vim.fn.escape(str, escape_chars)
    end

    local en = [[`qwertyuiop[]asdfghjkl;'zxcvbnm]]
    local ru = [[ёйцукенгшщзхъфывапролджэячсмить]]
    local en_shift = [[~QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>]]
    local ru_shift = [[ËЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ]]

    vim.opt.langmap = vim.fn.join({
      escape(ru_shift) .. ";" .. escape(en_shift),
      escape(ru) .. ";" .. escape(en),
    }, ",")
  '';

  plugins.langmapper = {
    enable = true;

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
  
    luaConfig.post = ''
      require("langmapper").hack_get_keymap()
    '';
  };
}
