{ ... }:
{
  colorschemes.catppuccin.settings.integrations.blink_cmp.enable = true;

  plugins.friendly-snippets.enable = true;
  plugins.blink-compat.enable = true;

  plugins.blink-cmp = {
    enable = true;
    settings = {
      snippets.preset = ''default'';
      appearance = {
        use_nvim_cmp_as_default = false;
        nerd_font_variant = "mono";
      };
      completion = {
        accept.auto_brackets.enabled = true;
        menu.draw.treesitter = [ "lsp" ];
        documentation = {
          auto_show = true;
          auto_show_delay_ms = 200;
          window.border = "single";
        };
      };
      sources = {
        default = [
          "lsp"
          "supermaven"
          "path"
          "snippets"
          "buffer"
        ];
        providers = {
          supermaven = {
            name = "supermaven";
            module = "blink.compat.source";
            score_offset = 100;
          };
        };
      };
      cmdline = {
        enabled = true;
        keymap.preset = "cmdline";
        completion = {
          list.selection.preselect = false;
          menu.auto_show.__raw = ''
            function()
              return vim.fn.getcmdtype() == ":"
            end
          '';
          ghost_text.enabled = true;
        };
      };
      keymap = {
        preset = "enter";
        "<C-y>" = [ "select_and_accept" ];
      };
    };
  };
}
