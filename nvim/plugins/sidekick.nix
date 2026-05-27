{ pkgs, ... }:
{
  plugins.sidekick = {
    enable = true;

    # Sidekick's nixpkgs package pulls Copilot LSP as a runtime dependency.
    # This configuration is CLI-only for OpenCode, so avoid the unfree Copilot runtime.
    package = pkgs.vimPlugins.sidekick-nvim.overrideAttrs (_old: {
      runtimeDeps = [ ];
    });
    settings = {
      # CLI-only mode: use Sidekick for OpenCode, not Copilot NES.
      nes.enabled = false;

      # NixVim currently checks this assertion path for Sidekick NES; keep it
      # disabled too so CLI-only builds do not require Copilot LSP.
      opts.nes.enabled = false;

      cli = {
        picker = "snacks";
        tools.opencode = { };
        win = {
          config.__raw = ''
            function(terminal)
              if terminal.tool.name ~= "opencode" then
                return
              end

              terminal.opts.keys.pass_ctrl_o = {
                "<c-o>",
                function(t)
                  if t.job and t:is_running() then
                    vim.api.nvim_chan_send(t.job, string.char(15))
                  end
                end,
                mode = "n",
                desc = "Pass Ctrl-O to OpenCode",
              }
            end
          '';
          split.width = 121;

          # Sidekick maps its terminal to SidekickChat, which links to
          # NormalFloat by default. Keep the split visually identical to
          # normal editor windows instead of rendering it dimmer.
          wo.winhighlight = "Normal:Normal,NormalNC:Normal,NormalFloat:Normal,EndOfBuffer:Normal,SignColumn:Normal";
        };
      };
    };
  };

  keymaps = [
    {
      mode = [
        "n"
      ];
      key = "<leader>aa";
      action.__raw = ''function() require("sidekick.cli").focus({ name = "opencode" }) end'';
      options.desc = "Sidekick Focus OpenCode";
    }
    {
      mode = [
        "n"
        "t"
        "i"
        "x"
      ];
      key = "<A-a>";
      action.__raw = ''function() require("sidekick.cli").toggle({ name = "opencode", focus = true }) end'';
      options.desc = "Sidekick Toggle OpenCode";
    }
    {
      mode = "n";
      key = "<leader>as";
      action.__raw = ''
        function()
          require("sidekick.cli").select({
            filter = { name = "opencode", installed = true },
            focus = true,
            auto = true,
          })
        end
      '';
      options.desc = "Select OpenCode CLI";
    }
    {
      mode = "n";
      key = "<leader>ad";
      action.__raw = ''function() require("sidekick.cli").close({ name = "opencode" }) end'';
      options.desc = "Detach OpenCode CLI Session";
    }
    {
      mode = [
        "n"
        "x"
      ];
      key = "<leader>at";
      action.__raw = ''function() require("sidekick.cli").send({ name = "opencode", msg = "{this}" }) end'';
      options.desc = "Send This to OpenCode";
    }
    {
      mode = "n";
      key = "<leader>af";
      action.__raw = ''function() require("sidekick.cli").send({ name = "opencode", msg = "{file}" }) end'';
      options.desc = "Send File to OpenCode";
    }
    {
      mode = "x";
      key = "<leader>av";
      action.__raw = ''function() require("sidekick.cli").send({ name = "opencode", msg = "{selection}" }) end'';
      options.desc = "Send Visual Selection to OpenCode";
    }
    {
      mode = [
        "n"
        "x"
      ];
      key = "<leader>ap";
      action.__raw = ''
        function()
          require("sidekick.cli").prompt({
            cb = function(_, text)
              if text then
                require("sidekick.cli").send({ name = "opencode", text = text })
              end
            end,
          })
        end
      '';
      options.desc = "Sidekick Select OpenCode Prompt";
    }
  ];
}
