{ ... }:
{
  plugins.toggleterm = {
    enable = true;
    settings = {
      direction = "float";
      open_mapping = null; # We'll use custom keymaps
      shade_terminals = false;
      highlights = {
        Normal = {
          link = "Normal";
        };
        NormalFloat = {
          link = "NormalFloat";
        };
        FloatBorder = {
          link = "FloatBorder";
        };
      };
    };
  };

  keymaps = [
    {
      mode = [
        "n"
        "t"
      ];
      key = "<C-/>";
      action = "<cmd>ToggleTerm direction=float<cr>";
      options.desc = "Toggle terminal";
    }
    {
      mode = [
        "n"
        "t"
      ];
      key = "<D-j>";
      action.__raw = ''
        function()
          local Terminal = require("toggleterm.terminal").Terminal

          if not _G.__jjui_term then
            _G.__jjui_term = Terminal:new({
              cmd = "jjui",
              direction = "float",
              hidden = true,
              close_on_exit = false,
              on_open = function(_)
                vim.cmd("startinsert!")
              end,
              on_exit = function(_, _, exit_code)
                -- If jjui exited successfully, hide the terminal.
                if exit_code == 0 then
                  pcall(vim.cmd, "close")
                end
                -- Always drop the instance so next open is fresh.
                _G.__jjui_term = nil
              end,
              -- Run in current Neovim cwd
              cwd = function()
                return (vim.uv or vim.loop).cwd() or vim.fn.getcwd()
              end,
            })
          end

          _G.__jjui_term:toggle()
        end
      '';
      options.desc = "jjui (float)";
    }
  ];
}
