{ lib, ... }:
{
  dependencies.opencode.enable = lib.mkForce false;

  plugins.opencode = {
    enable = true;
    autoLoad = true;
    settings = {
      provider.enabled = "snacks";

      keymap_prefix = "<leader>a";

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
