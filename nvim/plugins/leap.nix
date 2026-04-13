{ lib, ... }:
{
  colorschemes.catppuccin.settings.integrations.leap = true;

  extraConfigLua = lib.mkBefore ''
    do
      Leap = {}

      Leap.ft = function(ft, key_specific_args)
        key_specific_args = key_specific_args or {}

        local clever = require('leap.user').with_traversal_keys
        local clever_f, clever_t = clever('f', 'F'), clever('t', 'T')

        if ft == 'f' then
          key_specific_args.opts = clever_f
        elseif ft == 't' then
          key_specific_args.opts = clever_t
        end

        require('leap').leap(
          vim.tbl_deep_extend('keep', key_specific_args, {
            inputlen = 1,
            inclusive = true,
            opts = {
              -- Force autojump.
              labels = "",
              -- Match the modes where you don't need labels (`:h mode()`).
              safe_labels = vim.fn.mode(1):match('o') and "" or nil,
            },
          })
        )
      end
    end
  '';

  plugins.leap.enable = true;

  keymaps = [
    {
      mode = [
        "n"
        "x"
        "o"
      ];
      key = "s";
      action = "<Plug>(leap-forward)";
      options.desc = "Leap Forward to";
    }
    {
      mode = [
        "n"
        "x"
        "o"
      ];
      key = "ы";
      action = "<Plug>(leap-forward)";
      options.desc = "Leap Forward to";
    }
    {
      mode = [
        "n"
        "x"
        "o"
      ];
      key = "S";
      action = "<Plug>(leap-backward)";
      options.desc = "Leap Backward to";
    }
    {
      mode = [
        "n"
        "x"
        "o"
      ];
      key = "Ы";
      action = "<Plug>(leap-backward)";
      options.desc = "Leap Backward to";
    }
    {
      mode = [
        "n"
        "x"
        "o"
      ];
      key = "gs";
      action = "<Plug>(leap-from-window)";
      options.desc = "Leap from Windows";
    }
    {
      mode = [
        "n"
        "x"
        "o"
      ];
      key = "f";
      action.__raw = ''
        function()
          Leap.ft('f')
        end
      '';
    }
    {
      mode = [
        "n"
        "x"
        "o"
      ];
      key = "F";
      action.__raw = ''
        function()
          Leap.ft('f', {backward = true})
        end
      '';
    }
    {
      mode = [
        "n"
        "x"
        "o"
      ];
      key = "t";
      action.__raw = ''
        function()
          Leap.ft('t', {offset = -1})
        end
      '';
    }
    {
      mode = [
        "n"
        "x"
        "o"
      ];
      key = "T";
      action.__raw = ''
        function()
          Leap.ft('t', {backward = true, offset = 1})
        end
      '';
    }
  ];
}
