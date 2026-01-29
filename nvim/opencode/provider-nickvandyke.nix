# OpenCode integration via NickvanDyke/opencode.nvim (NixVim module `plugins.opencode`).
# This is the plugin currently used in this config.
{ ... }:
{
  plugins.opencode = {
    enable = true;
    autoLoad = true;
    settings = {
      # Use Snacks UI provider.
      provider.enabled = "snacks";

      # Keep your keymap prefix consistent across providers.
      # (Your actual keymaps are defined in `nvim/keymaps.nix` under <leader>a...)
      keymap_prefix = "<leader>a";

      # Keep the plugin from introducing a second keymap layer.
      # (We provide our own explicit keymaps.)
      default_global_keymaps = false;
    };
  };

  keymaps = [
    {
      mode = [
        "n"
        "x"
      ];
      key = "<leader>aa";
      action.__raw = ''function() require("opencode").ask("@this: ", { submit = true }) end'';
      options.desc = "Ask opencode…";
    }
    {
      mode = [
        "n"
        "x"
      ];
      key = "<leader>ax";
      action.__raw = ''function() require("opencode").select() end'';
      options.desc = "Execute opencode action…";
    }
    {
      mode = [
        "n"
        "x"
      ];
      key = "<leader>a.";
      action.__raw = ''function() require("opencode").toggle() end'';
      options.desc = "Toggle opencode…";
    }
    {
      mode = [
        "n"
        "v"
        "x"
      ];
      key = "go";
      action.__raw = ''function() return require("opencode").operator("@this ") end'';
      options.desc = "Add range to opencode";
    }
    {
      mode = "n";
      key = "goo";
      action.__raw = ''function() return require("opencode").operator("@this ") .. "_" end'';
      options.desc = "Add line to opencode";
    }
    {
      mode = "n";
      key = "<S-C-u>";
      action.__raw = ''function() require("opencode").command("session.half.page.up") end'';
      options.desc = "Scroll opencode up";
    }
    {
      mode = "n";
      key = "<S-C-d>";
      action.__raw = ''function() require("opencode").command("session.half.page.down") end'';
      options.desc = "Scroll opencode down";
    }
  ];
}
