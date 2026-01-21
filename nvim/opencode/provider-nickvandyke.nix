# OpenCode integration via NickvanDyke/opencode.nvim (NixVim module `plugins.opencode`).
# This is the plugin currently used in this config.
{ ... }:
{
  programs.nixvim.plugins.opencode = {
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
}
