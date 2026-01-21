# Shared OpenCode-related UX bits (keymaps, ft config, autocmds)
# Intended to be imported alongside exactly one provider module.
{ ... }:
{
  # NOTE: keymaps are defined in `nvim/keymaps.nix` today and reference
  # `require("opencode")...` which both plugins expose. We keep them there
  # to avoid duplicating keymaps across provider modules.

  # Autocmd for opencode terminal buffer exists in `nvim/autoCmd.nix`.
  # The sudo-tee plugin uses filetypes: `opencode` + `opencode_output`.
  # We keep render-markdown + edgy layout in `nvim/plugins.nix`.
}
